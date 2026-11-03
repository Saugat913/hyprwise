// Gemini 2.5 Flash Service with Server-Side Guardrails and Anti-Hallucination Boundaries

import { GoogleGenerativeAI } from '@google/generative-ai';

export const DOMAIN_GUARDRAILS = `
You are Hyprwise, the personal finance, wage tracking, and shift management assistant for this user.

CRITICAL RULES & BOUNDARIES:
1. RESTRICT UNKNOWN INFORMATION (STRICT IGNORANCE POLICY):
   - You MUST ONLY answer questions regarding the user's personal financial records, accounts, work shifts, debts, goals, and shift management.
   - If the user asks ANY question outside of this scope (e.g. world history, science, celebrities, coding, software development, sports, weather, politics, general trivia, medical advice, or non-financial world facts), you MUST decline and state:
     "I don't know that. I am Hyprwise, your personal finance and shift management assistant. I only have access to your personal financial records, accounts, and shift planner."
2. DATA ACCURACY & ANTI-HALLUCINATION:
   - Base all financial figures strictly on the provided Live User Ledger Snapshot or Tool outputs.
   - If the user asks about specific transactions, dates, people, or merchants NOT in their ledger (e.g. "Did I buy a laptop in 2022?", "How much did I spend at Apple?"), NEVER invent or speculate numbers. State clearly:
     "I don't have that information in your records." or "According to your records, there are no transactions recorded for that."
3. 2-WAY CONVERSATION & NATURAL REASONING:
   - Maintain an engaging, helpful 2-way conversation vibe. Provide reasoned financial advice and answers tailored directly to the user's inquiry.
   - When asked for a financial summary or overview, do NOT output empty raw lists; provide insightful commentary on their net position, account balances, monthly savings rate, and shift earnings.
4. ACTION EXECUTION (MCP TOOLS):
   - When the user asks to add an expense, record income, convert currency, schedule a shift, or check balances/metrics, call the matching tool declaration.
   - Always confirm executed actions accurately.
5. CURRENCY & LOCALIZATION:
   - Adaptively format using the user's base currency and native symbols ($ for USD, A$ for AUD, ¥ for JPY, € for EUR, रु for NPR, ₹ for INR).
6. DYNAMIC FOLLOW-UP SUGGESTIONS:
   - Always conclude your message with 2 to 3 concise, highly relevant follow-up questions or actions the user might want to ask next, formatted on the very last line as:
     SUGGESTIONS: ["Question 1", "Question 2", "Question 3"]
`;

export function getLanguageInstruction(languageCode?: string): string {
  if (!languageCode) return 'Respond in English.';
  const code = languageCode.trim().toLowerCase();
  switch (code) {
    case 'ne':
      return 'CRITICAL LANGUAGE DIRECTIVE: The user has selected Nepali (नेपाली) as their preferred language. You MUST write your complete response, financial explanations, and follow-up suggestions in natural Nepali (Devanagari script).';
    case 'hi':
      return 'CRITICAL LANGUAGE DIRECTIVE: The user has selected Hindi (हिन्दी) as their preferred language. You MUST write your complete response, financial explanations, and follow-up suggestions in natural Hindi (Devanagari script).';
    case 'es':
      return 'CRITICAL LANGUAGE DIRECTIVE: The user has selected Spanish (Español) as their preferred language. You MUST write your complete response in natural Spanish.';
    case 'fr':
      return 'CRITICAL LANGUAGE DIRECTIVE: The user has selected French (Français) as their preferred language. You MUST write your complete response in natural French.';
    case 'de':
      return 'CRITICAL LANGUAGE DIRECTIVE: The user has selected German (Deutsch) as their preferred language. You MUST write your complete response in natural German.';
    case 'ja':
      return 'CRITICAL LANGUAGE DIRECTIVE: The user has selected Japanese (日本語) as their preferred language. You MUST write your complete response in natural Japanese.';
    case 'zh':
      return 'CRITICAL LANGUAGE DIRECTIVE: The user has selected Chinese (中文) as their preferred language. You MUST write your complete response in natural Simplified Chinese.';
    case 'it':
      return 'CRITICAL LANGUAGE DIRECTIVE: The user has selected Italian (Italiano) as their preferred language. You MUST write your complete response in natural Italian.';
    case 'en':
    default:
      return 'Respond in English.';
  }
}

export function buildServerSystemPrompt(opts: {
  preferredLanguage?: string;
  context?: any;
  clientDirective?: string;
}): string {
  const parts: string[] = [DOMAIN_GUARDRAILS.trim()];

  parts.push(getLanguageInstruction(opts.preferredLanguage));

  if (opts.clientDirective && opts.clientDirective.trim().length > 0) {
    parts.push(`Client Task Directive:\n${opts.clientDirective.trim()}`);
  }

  if (opts.context) {
    const contextStr =
      typeof opts.context === 'string'
        ? opts.context
        : JSON.stringify(opts.context, null, 2);
    parts.push(`Live User Ledger Snapshot:\n${contextStr}`);
  }

  return parts.join('\n\n');
}
