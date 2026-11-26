// AI Chat & Reasoning Routes with Server-Side Guardrails and Payload Limits

import { Hono } from 'hono';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { type Bindings } from '../types';
import { resolveUser, computeQuotaSnapshot } from '../middleware/auth';
import { buildServerSystemPrompt } from '../services/gemini';

const MAX_MESSAGES = 24;
const MAX_TEXT_CHARS = 4000;
const MAX_IMAGE_BASE64_CHARS = 6 * 1024 * 1024; // ~4.5 MB image binary

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

    if (!Array.isArray(messages) || messages.length === 0) {
      return c.json({ error: 'invalid_request', message: 'messages array is required.' }, 400);
    }
    if (messages.length > MAX_MESSAGES) {
      return c.json(
        { error: 'payload_too_large', message: `At most ${MAX_MESSAGES} messages per request.` },
        413
      );
    }

    for (const m of messages) {
      if (typeof m?.content === 'string' && m.content.length > MAX_TEXT_CHARS) {
        return c.json(
          { error: 'payload_too_large', message: 'Message exceeds maximum length.' },
          413
        );
      }
      if (typeof m?.imageBase64 === 'string' && m.imageBase64.length > MAX_IMAGE_BASE64_CHARS) {
        return c.json(
          { error: 'payload_too_large', message: 'Receipt image exceeds maximum size.' },
          413
        );
      }
    }

    const user = await resolveUser(c, true, true);
    if (!user) {
      return c.json(
        {
          error: 'unauthorized',
          message: 'Please sign in with Google or Apple to use HyprAI.',
        },
        401
      );
    }
    const quota = computeQuotaSnapshot(user);
    const isPro = quota.activePro;

    let updatedUsed = quota.dailyAiQueriesUsed;
    let updatedLeft = quota.dailyAiQueriesLeft;

    // Strict server-side quota enforcement for free users (5 queries per day).
    // A tool-synthesis follow-up may pass quotaAlreadyConsumed=true ONLY if a query was already
    // consumed today (dailyAiQueriesUsed >= 1 && <= 5) and no new tools are requested.
    if (user && !isPro) {
      const isValidToolFollowUp =
        quotaAlreadyConsumed === true &&
        (!tools || (Array.isArray(tools) && tools.length === 0)) &&
        quota.dailyAiQueriesUsed >= 1 &&
        quota.dailyAiQueriesUsed <= 5;

      if (!isValidToolFollowUp) {
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
    const formattedTools =
      Array.isArray(tools) && tools.length > 0 ? [{ functionDeclarations: tools }] : undefined;

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

    const rawContents = messages.map((m: any) => {
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
        parts.push({ text: String(m.content) });
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
