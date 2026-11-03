// AI Chat & Reasoning Routes with Server-Side Guardrails

import { Hono } from 'hono';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { type Bindings } from '../types';
import { resolveUser, computeQuotaSnapshot } from '../middleware/auth';
import { buildServerSystemPrompt } from '../services/gemini';

export const aiRouter = new Hono<{ Bindings: Bindings }>();

aiRouter.post('/chat', async (c) => {
  try {
    const body = await c.req.json();
    const {
      messages,
      tools,
      preferredLanguage,
      clientDirective,
      context,
      quotaAlreadyConsumed,
    } = body;

    const user = await resolveUser(c, true);
    const quota = user
      ? computeQuotaSnapshot(user)
      : {
          todayStr: new Date().toISOString().slice(0, 10),
          activePro: false,
          dailyAiQueriesUsed: 0,
          dailyAiQueriesLeft: 5,
          limitReached: false,
        };
    const isPro = quota.activePro;

    let updatedUsed = quota.dailyAiQueriesUsed;
    let updatedLeft = quota.dailyAiQueriesLeft;

    // Strict server-side quota enforcement for free users (5 queries per day)
    if (user && !isPro) {
      if (!quotaAlreadyConsumed) {
        if (quota.dailyAiQueriesUsed >= 5) {
          return c.json(
            {
              error: 'pro_required',
              feature: 'assistant',
              limitReached: true,
              dailyAiQueriesUsed: quota.dailyAiQueriesUsed,
              dailyAiQueriesLeft: 0,
              message:
                'You have reached your 5 free AI queries for today. Upgrade to Hyprwise Pro for unlimited intelligent financial analysis.',
            },
            403
          );
        }
        updatedUsed = quota.dailyAiQueriesUsed + 1;
        updatedLeft = Math.max(0, 5 - updatedUsed);
        await c.env.DB.prepare(
          'UPDATE users SET dailyAiQueriesCount = ?, lastAiQueryDate = ? WHERE id = ?'
        )
          .bind(updatedUsed, quota.todayStr, user.id)
          .run();
      } else if (quota.dailyAiQueriesUsed > 5) {
        return c.json(
          {
            error: 'pro_required',
            feature: 'assistant',
            limitReached: true,
            dailyAiQueriesUsed: quota.dailyAiQueriesUsed,
            dailyAiQueriesLeft: 0,
            message:
              'You have reached your 5 free AI queries for today. Upgrade to Hyprwise Pro for unlimited intelligent financial analysis.',
          },
          403
        );
      }
    }

    const geminiApiKey = c.env.GEMINI_API_KEY || '';
    if (!geminiApiKey) {
      return c.json({
        content:
          'Hyprwise AI Server is running in on-device local mode. Please configure `GEMINI_API_KEY` in the server environment to enable live Gemini Flash 2.5 reasoning.',
        functionCalls: [],
        isPro,
        dailyAiQueriesUsed: updatedUsed,
        dailyAiQueriesLeft: updatedLeft,
        limitReached: false,
      });
    }

    const genAI = new GoogleGenerativeAI(geminiApiKey);
    const formattedTools = tools && tools.length > 0 ? [{ functionDeclarations: tools }] : undefined;

    // Build authoritative server-side system prompt with domain rules & anti-hallucination guardrails
    const systemPrompt = buildServerSystemPrompt({
      preferredLanguage,
      context,
      clientDirective,
    });

    const model = genAI.getGenerativeModel({
      model: 'gemini-2.5-flash',
      systemInstruction: systemPrompt,
      tools: formattedTools,
      generationConfig: {
        temperature: 0.1,
        maxOutputTokens: 1024,
      },
    });

    const rawContents = (messages || []).map((m: any) => {
      const parts: any[] = [];
      if (m.imageBase64) {
        parts.push({
          inlineData: {
            mimeType: m.imageMimeType || 'image/jpeg',
            data: m.imageBase64,
          },
        });
      }
      if (m.content) {
        parts.push({ text: m.content });
      }
      return {
        role: m.role === 'assistant' || m.role === 'model' ? 'model' : 'user',
        parts: parts.length > 0 ? parts : [{ text: '' }],
      };
    });

    // Merge consecutive same-role messages for strict role alternation
    const contents: any[] = [];
    for (const item of rawContents) {
      if (contents.length > 0 && contents[contents.length - 1].role === item.role) {
        contents[contents.length - 1].parts.push(...item.parts);
      } else {
        contents.push(item);
      }
    }

    const result = await model.generateContent({ contents });
    const response = await result.response;
    const candidate = response.candidates?.[0];

    const functionCalls: any[] = [];
    let textResponse = '';

    if (candidate?.content?.parts) {
      for (const part of candidate.content.parts) {
        if (part.text) {
          textResponse += part.text;
        }
        if (part.functionCall) {
          functionCalls.push({
            name: part.functionCall.name,
            args: part.functionCall.args,
          });
        }
      }
    }

    return c.json({
      content: textResponse || (functionCalls.length > 0 ? null : response.text()),
      functionCalls,
      isPro,
      dailyAiQueriesUsed: updatedUsed,
      dailyAiQueriesLeft: updatedLeft,
      limitReached: false,
    });
  } catch (e: any) {
    return c.json({ error: e.message || 'Gemini AI execution failed' }, 500);
  }
});
