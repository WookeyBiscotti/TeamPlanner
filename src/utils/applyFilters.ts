import { extractParentId } from '../api/relations';
import type { AreaPathMatch, ExclusionRule } from '../types/filters';
import type { WorkItem } from '../types/workItem';

function areaPathMatches(area: string, pattern: string, match: AreaPathMatch): boolean {
  if (match === 'exact') return area === pattern;
  return area === pattern || area.startsWith(`${pattern}\\`);
}

function parseTags(raw: unknown): string[] {
  if (typeof raw !== 'string' || !raw.trim()) return [];
  return raw
    .split(';')
    .map((tag) => tag.trim())
    .filter(Boolean);
}

function itemMatchesRule(item: WorkItem, rule: ExclusionRule): boolean {
  switch (rule.type) {
    case 'status': {
      const state = item.fields['System.State'];
      return typeof state === 'string' && rule.values.includes(state);
    }
    case 'parent': {
      const parentId = extractParentId(item);
      return parentId != null && rule.values.includes(String(parentId));
    }
    case 'parentSubtree': {
      return rule.values.includes(String(item.id));
    }
    case 'tag': {
      const tags = parseTags(item.fields['System.Tags']);
      return rule.values.some((value) => tags.includes(value));
    }
    case 'workItemType': {
      const type = item.fields['System.WorkItemType'];
      return typeof type === 'string' && rule.values.includes(type);
    }
    case 'id':
      return rule.values.includes(String(item.id));
    case 'areaPath': {
      const area = item.fields['System.AreaPath'];
      if (typeof area !== 'string') return false;
      const match = rule.areaMatch ?? 'under';
      return rule.values.some((pattern) => areaPathMatches(area, pattern, match));
    }
    default:
      return false;
  }
}

function descendantIdsForParents(items: WorkItem[], parentIds: number[]): Set<number> {
  const childrenByParent = new Map<number, number[]>();
  for (const item of items) {
    const parentId = extractParentId(item);
    if (parentId == null) continue;
    const list = childrenByParent.get(parentId) ?? [];
    list.push(item.id);
    childrenByParent.set(parentId, list);
  }

  const hidden = new Set<number>();
  const queue = [...parentIds];
  while (queue.length > 0) {
    const current = queue.shift()!;
    if (hidden.has(current)) continue;
    hidden.add(current);
    for (const childId of childrenByParent.get(current) ?? []) {
      queue.push(childId);
    }
  }
  return hidden;
}

export function applyExclusionRules(
  items: WorkItem[],
  rules: ExclusionRule[],
): WorkItem[] {
  if (rules.length === 0) return items;

  const subtreeRules = rules.filter((rule) => rule.type === 'parentSubtree');
  const subtreeHidden = new Set<number>();
  for (const rule of subtreeRules) {
    const parentIds = rule.values
      .map((value) => Number.parseInt(value, 10))
      .filter((id) => Number.isFinite(id));
    for (const id of descendantIdsForParents(items, parentIds)) {
      subtreeHidden.add(id);
    }
  }

  const otherRules = rules.filter((rule) => rule.type !== 'parentSubtree');

  return items.filter((item) => {
    if (subtreeHidden.has(item.id)) return false;
    return !otherRules.some((rule) => itemMatchesRule(item, rule));
  });
}

export function buildExclusionRuleLabel(
  type: ExclusionRule['type'],
  values: string[],
): string {
  const joined = values.join(', ');
  return `${type}: ${joined}`;
}
