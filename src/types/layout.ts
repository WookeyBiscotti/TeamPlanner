export type LayoutAlgorithm =
  | 'dagre-tb'
  | 'dagre-lr'
  | 'force'
  | 'radial'
  | 'grid';

export interface LayoutOption {
  id: LayoutAlgorithm;
  label: string;
  description: string;
}

export const LAYOUT_OPTIONS: LayoutOption[] = [
  {
    id: 'dagre-tb',
    label: 'Иерархия ↓',
    description: 'Слои сверху вниз (dagre)',
  },
  {
    id: 'dagre-lr',
    label: 'Иерархия →',
    description: 'Слои слева направо (dagre)',
  },
  {
    id: 'force',
    label: 'Силовой',
    description: 'Force-directed: связи притягивают, ноды отталкиваются',
  },
  {
    id: 'radial',
    label: 'Радиальный',
    description: 'Кольца вокруг корневых задач',
  },
  {
    id: 'grid',
    label: 'Сетка',
    description: 'Равномерная сетка по ID',
  },
];

export const DEFAULT_LAYOUT_ALGORITHM: LayoutAlgorithm = 'dagre-tb';
