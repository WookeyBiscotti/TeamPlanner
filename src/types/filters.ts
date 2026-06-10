export interface AreaLoadQuery {
  area: string;
  exact: boolean;
  excludeStates: string[];
  includeStates: string[];
  includeTags: string[];
}

export type ExclusionRuleType =
  | 'status'
  | 'parent'
  | 'parentSubtree'
  | 'tag'
  | 'workItemType'
  | 'id'
  | 'areaPath';

export type AreaPathMatch = 'exact' | 'under';

export interface ExclusionRule {
  id: string;
  type: ExclusionRuleType;
  values: string[];
  label: string;
  areaMatch?: AreaPathMatch;
}

export const EXCLUSION_RULE_LABELS: Record<ExclusionRuleType, string> = {
  status: 'Статус',
  parent: 'Родитель (прямой)',
  parentSubtree: 'Родитель (с поддеревом)',
  tag: 'Тег',
  workItemType: 'Тип задачи',
  id: 'ID задачи',
  areaPath: 'Area Path',
};

export const AREA_PATH_MATCH_LABELS: Record<AreaPathMatch, string> = {
  exact: 'Точное совпадение',
  under: 'Включая вложенные',
};
