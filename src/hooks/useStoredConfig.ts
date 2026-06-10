import { useCallback, useEffect, useState } from 'react';

import type { TfsConfig } from '../api/tfs';
import { DEFAULT_LAYOUT_ALGORITHM, type LayoutAlgorithm } from '../types/layout';
import { DEFAULT_NODE_FIELDS, type TNodeField } from '../types/workItem';

const CONFIG_KEY = 'planner.tfs.config';
const FIELDS_KEY = 'planner.node.fields';
const LAYOUT_KEY = 'planner.layout.algorithm';
const COLOR_BY_STATUS_KEY = 'planner.color.byStatus';
const STATUS_COLORS_KEY = 'planner.status.colors';

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

export function useStoredConfig() {
  const [config, setConfigState] = useState<TfsConfig | null>(null);
  const [nodeFields, setNodeFieldsState] = useState<TNodeField[]>(DEFAULT_NODE_FIELDS);
  const [layoutAlgorithm, setLayoutAlgorithmState] =
    useState<LayoutAlgorithm>(DEFAULT_LAYOUT_ALGORITHM);
  const [colorByStatus, setColorByStatusState] = useState(true);
  const [statusColors, setStatusColorsState] = useState<Record<string, string>>({});
  const [ready, setReady] = useState(false);

  useEffect(() => {
    const storedConfig = readJson<TfsConfig>(CONFIG_KEY);
    const storedFields = readJson<TNodeField[]>(FIELDS_KEY);
    const storedLayout = localStorage.getItem(LAYOUT_KEY);
    const storedColorByStatus = localStorage.getItem(COLOR_BY_STATUS_KEY);
    const storedStatusColors = readJson<Record<string, string>>(STATUS_COLORS_KEY);

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
  };
}
