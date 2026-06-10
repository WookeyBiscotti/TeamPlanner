export const DEFAULT_STATUS_COLORS: Record<string, string> = {
  New: '#3b82f6',
  Proposed: '#6366f1',
  'To Do': '#94a3b8',
  Active: '#22c55e',
  'In Progress': '#16a34a',
  Doing: '#16a34a',
  Resolved: '#a855f7',
  Done: '#14b8a6',
  Closed: '#64748b',
  Removed: '#475569',
  Cut: '#78716c',
};

export const FALLBACK_STATUS_COLOR = '#cbd5e1';

export function getStatusColor(
  state: unknown,
  customColors: Record<string, string> = {},
): string {
  if (typeof state !== 'string' || !state.trim()) return FALLBACK_STATUS_COLOR;
  const merged = { ...DEFAULT_STATUS_COLORS, ...customColors };
  return merged[state] ?? FALLBACK_STATUS_COLOR;
}

export function collectStatuses(items: { fields: Record<string, unknown> }[]): string[] {
  const states = new Set<string>();
  for (const item of items) {
    const state = item.fields['System.State'];
    if (typeof state === 'string' && state.trim()) {
      states.add(state);
    }
  }
  return [...states].sort((a, b) => a.localeCompare(b, 'ru'));
}
