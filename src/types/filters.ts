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
  | 'id';

export interface ExclusionRule {
  id: string;
  type: ExclusionRuleType;
  values: string[];
  label: string;
}

export const EXCLUSION_RULE_LABELS: Record<ExclusionRuleType, string> = {
  status: 'Статус',
  parent: 'Родитель (прямой)',
  parentSubtree: 'Родитель (с поддеревом)',
  tag: 'Тег',
  workItemType: 'Тип задачи',
  id: 'ID задачи',
};
