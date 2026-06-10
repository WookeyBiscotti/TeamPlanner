import { useCallback, useMemo, useState } from 'react';

import { getWorkItemWithRelations, getWorkItemsByArea } from './api/tfs';
import { ConfigDialog } from './components/ConfigDialog';
import { FieldSchemaSettings } from './components/FieldSchemaSettings';
import { ItemFilterPanel } from './components/ItemFilterPanel';
import { LoadPanel } from './components/LoadPanel';
import { StatusColorSettings } from './components/StatusColorSettings';
import { TaskGraph } from './components/TaskGraph';
import { useStoredConfig } from './hooks/useStoredConfig';
import type { AreaLoadQuery, ExclusionRule } from './types/filters';
import type { WorkItem } from './types/workItem';
import { applyExclusionRules } from './utils/applyFilters';

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
  } = useStoredConfig();

  const [loadedItems, setLoadedItems] = useState<WorkItem[]>([]);
  const [exclusionRules, setExclusionRules] = useState<ExclusionRule[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [schemaOpen, setSchemaOpen] = useState(false);
  const [statusColorsOpen, setStatusColorsOpen] = useState(false);
  const [configOpen, setConfigOpen] = useState(false);

  const visibleItems = useMemo(
    () => applyExclusionRules(loadedItems, exclusionRules),
    [loadedItems, exclusionRules],
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
        setExclusionRules([]);
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
        setExclusionRules([]);
        setSelectedId(id);
      } catch (exc) {
        setError(exc instanceof Error ? exc.message : String(exc));
      } finally {
        setLoading(false);
      }
    },
    [config],
  );

  const handleAddExclusionRule = useCallback((rule: ExclusionRule) => {
    setExclusionRules((prev) => [...prev, rule]);
  }, []);

  const handleRemoveExclusionRule = useCallback((id: string) => {
    setExclusionRules((prev) => prev.filter((rule) => rule.id !== id));
  }, []);

  const handleClearExclusionRules = useCallback(() => {
    setExclusionRules([]);
  }, []);

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
          <ItemFilterPanel
            loadedCount={loadedItems.length}
            visibleCount={visibleItems.length}
            rules={exclusionRules}
            onAddRule={handleAddExclusionRule}
            onRemoveRule={handleRemoveExclusionRule}
            onClearRules={handleClearExclusionRules}
          />
        </div>
        <TaskGraph
          items={visibleItems}
          nodeFields={nodeFields}
          selectedId={selectedId}
          layoutAlgorithm={layoutAlgorithm}
          onLayoutAlgorithmChange={setLayoutAlgorithm}
          colorByStatus={colorByStatus}
          statusColors={statusColors}
          onSelect={setSelectedId}
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
    </div>
  );
}
