export type WorkItemFields = Record<string, unknown>;

export interface WorkItemRelation {
  rel: string;
  url: string;
  attributes?: Record<string, unknown>;
}

export interface WorkItem {
  id: number;
  rev: number;
  url: string;
  fields: WorkItemFields;
  relations?: WorkItemRelation[];
}

export interface WorkItemsByAreaResult {
  area: string;
  exact: boolean;
  excludeStates: string[];
  includeStates: string[];
  includeTags: string[];
  count: number;
  items: WorkItem[];
}

export type EdgeKind =
  | 'parent-child'
  | 'dependency'
  | 'related'
  | 'remote-dependency'
  | 'test'
  | 'other';

export interface RelationTypeConfig {
  kind: EdgeKind;
  label: string;
  shortLabel: string;
  color: string;
}

export const RELATION_TYPES: RelationTypeConfig[] = [
  {
    kind: 'parent-child',
    label: 'Родитель → ребёнок',
    shortLabel: 'родитель',
    color: '#475569',
  },
  {
    kind: 'dependency',
    label: 'Предшественник → последователь',
    shortLabel: 'зависимость',
    color: '#dc2626',
  },
  {
    kind: 'related',
    label: 'Связанные',
    shortLabel: 'связан',
    color: '#2563eb',
  },
  {
    kind: 'remote-dependency',
    label: 'Удалённая зависимость',
    shortLabel: 'удал. зав.',
    color: '#ea580c',
  },
  {
    kind: 'test',
    label: 'Тестирование',
    shortLabel: 'тест',
    color: '#7c3aed',
  },
  {
    kind: 'other',
    label: 'Прочие связи',
    shortLabel: 'прочее',
    color: '#94a3b8',
  },
];

export const ALL_EDGE_KINDS: EdgeKind[] = RELATION_TYPES.map((item) => item.kind);

export function relationConfig(kind: EdgeKind): RelationTypeConfig {
  return RELATION_TYPES.find((item) => item.kind === kind) ?? RELATION_TYPES.at(-1)!;
}

export interface GraphEdge {
  id: string;
  source: string;
  target: string;
  kind: EdgeKind;
  rel: string;
}

export interface TNodeField {
  key: string;
  label: string;
}

export const DEFAULT_NODE_FIELDS: TNodeField[] = [
  { key: 'System.Id', label: 'ID' },
  { key: 'System.Title', label: 'Название' },
  { key: 'System.State', label: 'Статус' },
  { key: 'System.WorkItemType', label: 'Тип' },
  { key: 'System.AssignedTo', label: 'Исполнитель' },
];

export const AVAILABLE_NODE_FIELDS: TNodeField[] = [
  ...DEFAULT_NODE_FIELDS,
  { key: 'System.AreaPath', label: 'Area' },
  { key: 'System.IterationPath', label: 'Итерация' },
  { key: 'System.Tags', label: 'Теги' },
  { key: 'Microsoft.VSTS.Scheduling.StoryPoints', label: 'Story Points' },
  { key: 'Microsoft.VSTS.Scheduling.OriginalEstimate', label: 'Оценка' },
  { key: 'Microsoft.VSTS.Scheduling.RemainingWork', label: 'Осталось' },
  { key: 'Microsoft.VSTS.Scheduling.CompletedWork', label: 'Факт' },
  { key: 'System.CreatedDate', label: 'Создано' },
  { key: 'System.ChangedDate', label: 'Изменено' },
];
