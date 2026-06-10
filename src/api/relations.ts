import type { EdgeKind, WorkItem, WorkItemRelation } from '../types/workItem';

export function workItemIdFromUrl(url: string): number | null {
  const httpsMatch = /\/workItems\/(\d+)(?:\?|$)/i.exec(url);
  if (httpsMatch) return Number.parseInt(httpsMatch[1], 10);

  const vstfsMatch = /\/WorkItem\/(\d+)$/i.exec(url);
  if (vstfsMatch) return Number.parseInt(vstfsMatch[1], 10);

  return null;
}

export function classifyRelation(rel: string): EdgeKind {
  if (rel.includes('Hierarchy')) return 'parent-child';
  if (rel.includes('Remote') && rel.includes('Dependency')) return 'remote-dependency';
  if (rel.includes('Dependency')) return 'dependency';
  if (rel === 'System.LinkTypes.Related') return 'related';
  if (rel.includes('TestCase') || rel.includes('Test')) return 'test';
  return 'other';
}

export interface ParsedRelationEdge {
  source: number;
  target: number;
  kind: EdgeKind;
  rel: string;
}

/** Направление ребра: от источника связи к цели (родитель→ребёнок, блокер→задача и т.д.). */
export function parseRelationEdge(
  itemId: number,
  relation: WorkItemRelation,
): ParsedRelationEdge | null {
  const relatedId = workItemIdFromUrl(relation.url);
  if (relatedId == null || relatedId === itemId) return null;

  const rel = relation.rel;
  const kind = classifyRelation(rel);

  if (rel === 'System.LinkTypes.Hierarchy-Reverse') {
    return { source: relatedId, target: itemId, kind, rel };
  }
  if (rel === 'System.LinkTypes.Hierarchy-Forward') {
    return { source: itemId, target: relatedId, kind, rel };
  }
  if (
    rel === 'System.LinkTypes.Dependency-Reverse' ||
    rel === 'System.LinkTypes.Remote.Dependency-Reverse'
  ) {
    return { source: relatedId, target: itemId, kind, rel };
  }
  if (
    rel === 'System.LinkTypes.Dependency-Forward' ||
    rel === 'System.LinkTypes.Remote.Dependency-Forward'
  ) {
    return { source: itemId, target: relatedId, kind, rel };
  }

  return { source: itemId, target: relatedId, kind, rel };
}

export function extractAllRelationEdges(item: WorkItem): ParsedRelationEdge[] {
  const edges: ParsedRelationEdge[] = [];
  for (const relation of item.relations ?? []) {
    const parsed = parseRelationEdge(item.id, relation);
    if (parsed) edges.push(parsed);
  }
  return edges;
}

export function relatedWorkItemIds(item: WorkItem): number[] {
  const ids = new Set<number>();
  for (const edge of extractAllRelationEdges(item)) {
    ids.add(edge.source);
    ids.add(edge.target);
  }
  ids.delete(item.id);
  return [...ids];
}

/** @deprecated Используйте extractAllRelationEdges */
export function extractParentId(item: WorkItem): number | null {
  for (const relation of item.relations ?? []) {
    if (relation.rel === 'System.LinkTypes.Hierarchy-Reverse') {
      const id = workItemIdFromUrl(relation.url);
      if (id != null) return id;
    }
  }
  return null;
}

/** @deprecated Используйте extractAllRelationEdges */
export function extractBlockerIds(item: WorkItem): number[] {
  const ids: number[] = [];
  for (const relation of item.relations ?? []) {
    if (relation.rel !== 'System.LinkTypes.Dependency-Reverse') continue;
    const id = workItemIdFromUrl(relation.url);
    if (id != null) ids.push(id);
  }
  return ids;
}
