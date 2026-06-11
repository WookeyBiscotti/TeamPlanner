export interface AreaLoadQuery {
  area: string;
  exact: boolean;
  excludeStates: string[];
  includeStates: string[];
  includeTags: string[];
}

export type FilterUIMode = 'query' | 'visual';

export type FilterEffect = 'hide' | 'highlight';
