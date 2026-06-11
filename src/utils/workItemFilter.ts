import { createArrayFilter, getOptionsMap } from '@svar-ui/react-filter';
import type { IFilterSet } from '@svar-ui/filter-store';

import type { WorkItem } from '../types/workItem';

export interface WorkItemFilterRow {
  id: number;
  title: string;
  state: string;
  type: string;
  areaPath: string;
  iterationPath: string;
  tags: string;
  assignedTo: string;
  description: string;
}

export const WORK_ITEM_FILTER_FIELDS = [
  { id: 'id', label: 'ID', type: 'number' as const },
  { id: 'title', label: 'Название', type: 'text' as const },
  { id: 'state', label: 'Статус', type: 'text' as const },
  { id: 'type', label: 'Тип', type: 'text' as const },
  { id: 'areaPath', label: 'Area Path', type: 'text' as const },
  { id: 'iterationPath', label: 'Итерация', type: 'text' as const },
  { id: 'tags', label: 'Теги', type: 'text' as const },
  { id: 'assignedTo', label: 'Исполнитель', type: 'text' as const },
  { id: 'description', label: 'Описание', type: 'text' as const },
];

function fieldText(value: unknown): string {
  if (value == null || value === '') return '';
  if (typeof value === 'object' && value !== null) {
    const record = value as Record<string, unknown>;
    if (typeof record.displayName === 'string') return record.displayName;
    if (typeof record.uniqueName === 'string') return record.uniqueName;
    return JSON.stringify(value);
  }
  return String(value);
}

export function workItemToFilterRow(item: WorkItem): WorkItemFilterRow {
  const fields = item.fields;
  return {
    id: item.id,
    title: fieldText(fields['System.Title']),
    state: fieldText(fields['System.State']),
    type: fieldText(fields['System.WorkItemType']),
    areaPath: fieldText(fields['System.AreaPath']),
    iterationPath: fieldText(fields['System.IterationPath']),
    tags: fieldText(fields['System.Tags']),
    assignedTo: fieldText(fields['System.AssignedTo']),
    description: fieldText(fields['System.Description']),
  };
}

export function buildFilterOptions(items: WorkItem[]) {
  const rows = items.map(workItemToFilterRow);
  return getOptionsMap(rows, WORK_ITEM_FILTER_FIELDS);
}

export function isActiveFilter(value: unknown): value is IFilterSet {
  if (!value || typeof value !== 'object') return false;
  const rules = (value as IFilterSet).rules;
  return Array.isArray(rules) && rules.length > 0;
}

/** null = фильтр не активен, все задачи совпадают */
export function getMatchedItemIds(
  items: WorkItem[],
  filterValue: unknown,
): Set<number> | null {
  if (!isActiveFilter(filterValue)) return null;

  const rows = items.map(workItemToFilterRow);
  const filterFn = createArrayFilter(filterValue, {}, WORK_ITEM_FILTER_FIELDS);
  if (!filterFn) return null;

  return new Set(filterFn(rows).map((row: WorkItemFilterRow) => row.id));
}

export function stripHtml(html: string): string {
  if (!html.trim()) return '';
  try {
    const doc = new DOMParser().parseFromString(html, 'text/html');
    return doc.body.textContent?.replace(/\s+/g, ' ').trim() ?? '';
  } catch {
    return html.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
  }
}

export function getWorkItemDescription(item: WorkItem): string {
  const raw = item.fields['System.Description'];
  if (typeof raw !== 'string' || !raw.trim()) return '';
  return stripHtml(raw);
}
