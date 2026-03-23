/**
 * Canonical channel type names — use these constants instead of string literals.
 * Avoids typos and enables refactoring.
 */
export const CHANNEL = {
  TELEGRAM: "telegram",
  DISCORD: "discord",
  SLACK: "slack",
  WHATSAPP: "whatsapp",
  MATTERMOST: "mattermost",
  LINE: "line",
  TEAMS: "teams",
  WEBHOOK: "webhook",
  API: "api",
} as const;

export type ChannelName = (typeof CHANNEL)[keyof typeof CHANNEL];
