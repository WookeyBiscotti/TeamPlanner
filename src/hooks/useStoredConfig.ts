import { useCallback, useEffect, useState } from 'react';

import type { TfsConfig } from '../api/tfs';
import { DEFAULT_LAYOUT_ALGORITHM, type LayoutAlgorithm } from '../types/layout';
import type { FilterEffect, FilterUIMode } from '../types/filters';
import { DEFAULT_NODE_FIELDS, type TNodeField } from '../types/workItem';

const CONFIG_KEY = 'planner.tfs.config';
const FIELDS_KEY = 'planner.node.fields';
const LAYOUT_KEY = 'planner.layout.algorithm';
const COLOR_BY_STATUS_KEY = 'planner.color.byStatus';
const STATUS_COLORS_KEY = 'planner.status.colors';
const FILTER_MODE_KEY = 'planner.filter.mode';
const FILTER_EFFECT_KEY = 'planner.filter.effect';
const HIGHLIGHT_COLOR_KEY = 'planner.filter.highlightColor';

function readJson<T>(key: string): T | null {
  try {
    const raw = localStorage.getItem(key);
    if (!raw) return null;
    return JSON.parse(raw) as T;
  } catch {
    return null;
  }
}

function isLayoutAlgorithm(value: string): value is LayoutAlgorithm {
  return ['dagre-tb', 'dagre-lr', 'force', 'radial', 'grid'].includes(value);
}

function isFilterMode(value: string): value is FilterUIMode {
  return value === 'query' || value === 'visual';
}

function isFilterEffect(value: string): value is FilterEffect {
  return value === 'hide' || value === 'highlight';
}

export function useStoredConfig() {
  const [config, setConfigState] = useState<TfsConfig | null>(null);
  const [nodeFields, setNodeFieldsState] = useState<TNodeField[]>(DEFAULT_NODE_FIELDS);
  const [layoutAlgorithm, setLayoutAlgorithmState] =
    useState<LayoutAlgorithm>(DEFAULT_LAYOUT_ALGORITHM);
  const [colorByStatus, setColorByStatusState] = useState(true);
  const [statusColors, setStatusColorsState] = useState<Record<string, string>>({});
  const [filterMode, setFilterModeState] = useState<FilterUIMode>('query');
  const [filterEffect, setFilterEffectState] = useState<FilterEffect>('hide');
  const [highlightColor, setHighlightColorState] = useState('#f59e0b');
  const [ready, setReady] = useState(false);

  useEffect(() => {
    const storedConfig = readJson<TfsConfig>(CONFIG_KEY);
    const storedFields = readJson<TNodeField[]>(FIELDS_KEY);
    const storedLayout = localStorage.getItem(LAYOUT_KEY);
    const storedColorByStatus = localStorage.getItem(COLOR_BY_STATUS_KEY);
    const storedStatusColors = readJson<Record<string, string>>(STATUS_COLORS_KEY);
    const storedFilterMode = localStorage.getItem(FILTER_MODE_KEY);
    const storedFilterEffect = localStorage.getItem(FILTER_EFFECT_KEY);
    const storedHighlightColor = localStorage.getItem(HIGHLIGHT_COLOR_KEY);

    if (storedConfig?.baseUrl && storedConfig?.pat) {
      setConfigState(storedConfig);
    }
    if (storedFields?.length) {
      setNodeFieldsState(storedFields);
    }
    if (storedLayout && isLayoutAlgorithm(storedLayout)) {
      setLayoutAlgorithmState(storedLayout);
    }
    if (storedColorByStatus != null) {
      setColorByStatusState(storedColorByStatus === 'true');
    }
    if (storedStatusColors) {
      setStatusColorsState(storedStatusColors);
    }
    if (storedFilterMode && isFilterMode(storedFilterMode)) {
      setFilterModeState(storedFilterMode);
    }
    if (storedFilterEffect && isFilterEffect(storedFilterEffect)) {
      setFilterEffectState(storedFilterEffect);
    }
    if (storedHighlightColor) {
      setHighlightColorState(storedHighlightColor);
    }
    setReady(true);
  }, []);

  const setConfig = useCallback((next: TfsConfig) => {
    localStorage.setItem(CONFIG_KEY, JSON.stringify(next));
    setConfigState(next);
  }, []);

  const clearConfig = useCallback(() => {
    localStorage.removeItem(CONFIG_KEY);
    setConfigState(null);
  }, []);

  const setNodeFields = useCallback((next: TNodeField[]) => {
    localStorage.setItem(FIELDS_KEY, JSON.stringify(next));
    setNodeFieldsState(next);
  }, []);

  const setLayoutAlgorithm = useCallback((next: LayoutAlgorithm) => {
    localStorage.setItem(LAYOUT_KEY, next);
    setLayoutAlgorithmState(next);
  }, []);

  const setColorByStatus = useCallback((next: boolean) => {
    localStorage.setItem(COLOR_BY_STATUS_KEY, String(next));
    setColorByStatusState(next);
  }, []);

  const setStatusColors = useCallback((next: Record<string, string>) => {
    localStorage.setItem(STATUS_COLORS_KEY, JSON.stringify(next));
    setStatusColorsState(next);
  }, []);

  const setFilterMode = useCallback((next: FilterUIMode) => {
    localStorage.setItem(FILTER_MODE_KEY, next);
    setFilterModeState(next);
  }, []);

  const setFilterEffect = useCallback((next: FilterEffect) => {
    localStorage.setItem(FILTER_EFFECT_KEY, next);
    setFilterEffectState(next);
  }, []);

  const setHighlightColor = useCallback((next: string) => {
    localStorage.setItem(HIGHLIGHT_COLOR_KEY, next);
    setHighlightColorState(next);
  }, []);

  return {
    ready,
    config,
    setConfig,
    clearConfig,
    nodeFields,
    setNodeFields,
    layoutAlgorithm,
    setLayoutAlgorithm,
    colorByStatus,
    setColorByStatus,
    statusColors,
    setStatusColors,
    filterMode,
    setFilterMode,
    filterEffect,
    setFilterEffect,
    highlightColor,
    setHighlightColor,
  };
}
