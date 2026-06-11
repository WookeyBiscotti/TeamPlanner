import { useCallback, useMemo, useState } from 'react';
import type { IFilterSet } from '@svar-ui/filter-store';

import { findMissingChildIds } from './api/relations';
import { getWorkItemWithRelations, getWorkItemsByArea, loadMissingChildren } from './api/tfs';
import { ConfigDialog } from './components/ConfigDialog';
import { FieldSchemaSettings } from './components/FieldSchemaSettings';
import { LoadPanel } from './components/LoadPanel';
import { RawDataModal } from './components/RawDataModal';
import { StatusColorSettings } from './components/StatusColorSettings';
import { TaskFilterPanel } from './components/TaskFilterPanel';
import { TaskGraph } from './components/TaskGraph';
import { useStoredConfig } from './hooks/useStoredConfig';
import type { AreaLoadQuery } from './types/filters';
import type { WorkItem } from './types/workItem';
import { getMatchedItemIds } from './utils/workItemFilter';

export default function App() {
  const {
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
  } = useStoredConfig();

  const [loadedItems, setLoadedItems] = useState<WorkItem[]>([]);
  const [filterValue, setFilterValue] = useState<IFilterSet | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [expandedIds, setExpandedIds] = useState<Set<number>>(() => new Set());
  const [rawItem, setRawItem] = useState<WorkItem | null>(null);
  const [schemaOpen, setSchemaOpen] = useState(false);
  const [statusColorsOpen, setStatusColorsOpen] = useState(false);
  const [configOpen, setConfigOpen] = useState(false);

  const matchedIds = useMemo(
    () => getMatchedItemIds(loadedItems, filterValue),
    [loadedItems, filterValue],
  );

  const graphItems = useMemo(() => {
    if (filterEffect !== 'hide' || matchedIds == null) return loadedItems;
    return loadedItems.filter((item) => matchedIds.has(item.id));
  }, [loadedItems, filterEffect, matchedIds]);

  const highlightedIds = useMemo(() => {
    if (filterEffect !== 'highlight' || matchedIds == null) return null;
    return matchedIds;
  }, [filterEffect, matchedIds]);

  const missingChildrenCount = useMemo(
    () => findMissingChildIds(loadedItems).length,
    [loadedItems],
  );

  const showConfig = ready && (!config || configOpen);

  const handleLoadByArea = useCallback(
    async (query: AreaLoadQuery) => {
      if (!config) return;
      setLoading(true);
      setError('');
      try {
        const data = await getWorkItemsByArea(config, query.area, {
          exact: query.exact,
          excludeStates: query.excludeStates,
          includeStates: query.includeStates,
          includeTags: query.includeTags,
        });
        setLoadedItems(data.items);
        setFilterValue(null);
        setExpandedIds(new Set());
        setSelectedId(null);
      } catch (exc) {
        setError(exc instanceof Error ? exc.message : String(exc));
      } finally {
        setLoading(false);
      }
    },
    [config],
  );

  const handleLoadById = useCallback(
    async (id: number) => {
      if (!config) return;
      setLoading(true);
      setError('');
      try {
        const loaded = await getWorkItemWithRelations(config, id);
        setLoadedItems(loaded);
        setFilterValue(null);
        setExpandedIds(new Set());
        setSelectedId(id);
      } catch (exc) {
        setError(exc instanceof Error ? exc.message : String(exc));
      } finally {
        setLoading(false);
      }
    },
    [config],
  );

  const handleLoadChildren = useCallback(async () => {
    if (!config || missingChildrenCount === 0) return;
    setLoading(true);
    setError('');
    try {
      const { items } = await loadMissingChildren(config, loadedItems);
      setLoadedItems(items);
    } catch (exc) {
      setError(exc instanceof Error ? exc.message : String(exc));
    } finally {
      setLoading(false);
    }
  }, [config, loadedItems, missingChildrenCount]);

  const handleToggleExpand = useCallback((id: number) => {
    setExpandedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }, []);

  const handleShowRaw = useCallback(
    (id: number) => {
      const item = loadedItems.find((entry) => entry.id === id) ?? null;
      setRawItem(item);
    },
    [loadedItems],
  );

  if (!ready) {
    return <div className="app-loading">Загрузка…</div>;
  }

  return (
    <div className="app">
      <header className="app-header">
        <div>
          <h1>Planner</h1>
          <p className="muted">Граф задач TFS / Azure DevOps</p>
        </div>
        <div className="header-actions">
          <button type="button" onClick={() => setSchemaOpen(true)}>
            Схема полей
          </button>
          <button type="button" onClick={() => setStatusColorsOpen(true)}>
            Цвета статусов
          </button>
          <button
            type="button"
            onClick={() => setConfigOpen(true)}
            disabled={!config}
          >
            Настройки API
          </button>
          <button type="button" className="ghost" onClick={clearConfig}>
            Выйти
          </button>
        </div>
      </header>

      {error && <div className="banner error">{error}</div>}
      {loading && <div className="banner">Загрузка задач…</div>}

      <main className="app-main">
        <div className="sidebar">
          <LoadPanel
            loading={loading}
            onLoadByArea={handleLoadByArea}
            onLoadById={handleLoadById}
          />
          <TaskFilterPanel
            items={loadedItems}
            missingChildrenCount={missingChildrenCount}
            loading={loading}
            filterMode={filterMode}
            onFilterModeChange={setFilterMode}
            filterValue={filterValue}
            onFilterChange={setFilterValue}
            filterEffect={filterEffect}
            onFilterEffectChange={setFilterEffect}
            highlightColor={highlightColor}
            onHighlightColorChange={setHighlightColor}
            matchedCount={matchedIds?.size ?? null}
            onLoadChildren={handleLoadChildren}
          />
        </div>
        <TaskGraph
          items={graphItems}
          nodeFields={nodeFields}
          selectedId={selectedId}
          expandedIds={expandedIds}
          highlightedIds={highlightedIds}
          highlightColor={highlightColor}
          layoutAlgorithm={layoutAlgorithm}
          onLayoutAlgorithmChange={setLayoutAlgorithm}
          colorByStatus={colorByStatus}
          statusColors={statusColors}
          onSelect={setSelectedId}
          onToggleExpand={handleToggleExpand}
          onShowRaw={handleShowRaw}
        />
      </main>

      <ConfigDialog
        open={showConfig}
        initial={config}
        onSave={(next) => {
          setConfig(next);
          setConfigOpen(false);
        }}
      />

      <FieldSchemaSettings
        open={schemaOpen}
        selected={nodeFields}
        onChange={setNodeFields}
        onClose={() => setSchemaOpen(false)}
      />

      <StatusColorSettings
        open={statusColorsOpen}
        items={loadedItems}
        colorByStatus={colorByStatus}
        statusColors={statusColors}
        onColorByStatusChange={setColorByStatus}
        onStatusColorsChange={setStatusColors}
        onClose={() => setStatusColorsOpen(false)}
      />

      <RawDataModal item={rawItem} onClose={() => setRawItem(null)} />
    </div>
  );
}
