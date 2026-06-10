import { useCallback, useEffect, useState } from 'react';

import type { TfsConfig } from '../api/tfs';
import { DEFAULT_NODE_FIELDS, type TNodeField } from '../types/workItem';

const CONFIG_KEY = 'planner.tfs.config';
const FIELDS_KEY = 'planner.node.fields';

function readJson<T>(key: string): T | null {
  try {
    const raw = localStorage.getItem(key);
    if (!raw) return null;
    return JSON.parse(raw) as T;
  } catch {
    return null;
  }
}

export function useStoredConfig() {
  const [config, setConfigState] = useState<TfsConfig | null>(null);
  const [nodeFields, setNodeFieldsState] = useState<TNodeField[]>(DEFAULT_NODE_FIELDS);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    const storedConfig = readJson<TfsConfig>(CONFIG_KEY);
    const storedFields = readJson<TNodeField[]>(FIELDS_KEY);
    if (storedConfig?.baseUrl && storedConfig?.pat) {
      setConfigState(storedConfig);
    }
    if (storedFields?.length) {
      setNodeFieldsState(storedFields);
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

  return {
    ready,
    config,
    setConfig,
    clearConfig,
    nodeFields,
    setNodeFields,
  };
}
