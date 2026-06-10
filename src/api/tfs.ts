import { relatedWorkItemIds } from './relations';
import type { WorkItem, WorkItemsByAreaResult } from '../types/workItem';

export { extractBlockerIds, extractParentId, workItemIdFromUrl } from './relations';

const API_VERSION = '6.0';

export interface TfsConfig {
  baseUrl: string;
  pat: string;
}

function normalizeBaseUrl(url: string): string {
  return url.trim().replace(/\/+$/, '');
}

function authHeader(pat: string): string {
  const token = btoa(`:${pat}`);
  return `Basic ${token}`;
}

async function tfsFetch(
  config: TfsConfig,
  path: string,
  init?: RequestInit,
): Promise<Response> {
  const url = `${normalizeBaseUrl(config.baseUrl)}${path}`;
  const response = await fetch(url, {
    ...init,
    headers: {
      Authorization: authHeader(config.pat),
      'Content-Type': 'application/json',
      ...(init?.headers ?? {}),
    },
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`HTTP ${response.status}: ${body || response.statusText}`);
  }

  return response;
}

function parseExcludeStates(raw: string[]): string[] {
  const result: string[] = [];
  for (const entry of raw) {
    for (const part of entry.split(',')) {
      const trimmed = part.trim();
      if (trimmed) result.push(trimmed);
    }
  }
  return [...new Set(result)];
}

function buildAreaWiql(area: string, exact: boolean, excludeStates: string[]): string {
  const escapedArea = area.replace(/'/g, "''");
  const areaClause = exact
    ? `[System.AreaPath] = '${escapedArea}'`
    : `[System.AreaPath] UNDER '${escapedArea}'`;

  const states = parseExcludeStates(excludeStates);
  const stateClause =
    states.length > 0
      ? ` AND [System.State] NOT IN (${states.map((s) => `'${s.replace(/'/g, "''")}'`).join(', ')})`
      : '';

  return `SELECT [System.Id] FROM WorkItems WHERE ${areaClause}${stateClause} ORDER BY [System.Id]`;
}

async function queryWorkItemIds(
  config: TfsConfig,
  wiql: string,
): Promise<number[]> {
  const response = await tfsFetch(
    config,
    `/_apis/wit/wiql?api-version=${API_VERSION}`,
    {
      method: 'POST',
      body: JSON.stringify({ query: wiql }),
    },
  );
  const data = (await response.json()) as {
    workItems?: Array<{ id: number }>;
  };
  return (data.workItems ?? []).map((item) => item.id);
}

async function fetchWorkItemsBatch(
  config: TfsConfig,
  ids: number[],
): Promise<WorkItem[]> {
  if (ids.length === 0) return [];

  const batchSize = 200;
  const items: WorkItem[] = [];

  for (let offset = 0; offset < ids.length; offset += batchSize) {
    const chunk = ids.slice(offset, offset + batchSize);
    const response = await tfsFetch(
      config,
      `/_apis/wit/workitemsbatch?api-version=${API_VERSION}`,
      {
        method: 'POST',
        body: JSON.stringify({ ids: chunk, $expand: 'Relations' }),
      },
    );
    const data = (await response.json()) as { value?: WorkItem[] };
    items.push(...(data.value ?? []));
  }

  return items.sort((a, b) => a.id - b.id);
}

export async function getWorkItem(config: TfsConfig, id: number): Promise<WorkItem> {
  const response = await tfsFetch(
    config,
    `/_apis/wit/workitems/${id}?$expand=relations&api-version=${API_VERSION}`,
  );
  return (await response.json()) as WorkItem;
}

/** Загружает задачу и все связанные work items из её relations. */
export async function getWorkItemWithRelations(
  config: TfsConfig,
  id: number,
): Promise<WorkItem[]> {
  const root = await getWorkItem(config, id);
  const relatedIds = relatedWorkItemIds(root);
  if (relatedIds.length === 0) return [root];

  const related = await fetchWorkItemsBatch(config, relatedIds);
  const byId = new Map<number, WorkItem>([[root.id, root]]);
  for (const item of related) {
    byId.set(item.id, item);
  }
  return [...byId.values()].sort((a, b) => a.id - b.id);
}

export async function getWorkItemsByArea(
  config: TfsConfig,
  area: string,
  options: { exact?: boolean; excludeStates?: string[] } = {},
): Promise<WorkItemsByAreaResult> {
  const exact = options.exact ?? false;
  const excludeStates = options.excludeStates ?? [];
  const wiql = buildAreaWiql(area, exact, excludeStates);
  const ids = await queryWorkItemIds(config, wiql);
  const items = await fetchWorkItemsBatch(config, ids);

  return {
    area,
    exact,
    excludeStates: parseExcludeStates(excludeStates),
    count: items.length,
    items,
  };
}

export function fieldDisplayValue(fields: WorkItem['fields'], key: string): string {
  const value = fields[key];
  if (value == null || value === '') return '—';

  if (typeof value === 'object' && value !== null) {
    const record = value as Record<string, unknown>;
    if (typeof record.displayName === 'string') return record.displayName;
    if (typeof record.uniqueName === 'string') return record.uniqueName;
    return JSON.stringify(value);
  }

  if (typeof value === 'string' && /^\d{4}-\d{2}-\d{2}T/.test(value)) {
    try {
      return new Date(value).toLocaleString('ru-RU');
    } catch {
      return value;
    }
  }

  return String(value);
}
