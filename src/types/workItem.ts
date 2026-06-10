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
  count: number;
  items: WorkItem[];
}

export type EdgeKind = 'parent' | 'blocker';

export interface GraphEdge {
  id: string;
  source: string;
  target: string;
  kind: EdgeKind;
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
