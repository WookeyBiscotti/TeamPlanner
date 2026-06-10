import { useCallback, useState } from 'react';

import { getWorkItemWithRelations, getWorkItemsByArea } from './api/tfs';
import { ConfigDialog } from './components/ConfigDialog';
import { FieldSchemaSettings } from './components/FieldSchemaSettings';
import { LoadPanel } from './components/LoadPanel';
import { TaskGraph } from './components/TaskGraph';
import { useStoredConfig } from './hooks/useStoredConfig';
import type { WorkItem } from './types/workItem';

export default function App() {
  const {
    ready,
    config,
    setConfig,
    clearConfig,
    nodeFields,
    setNodeFields,
  } = useStoredConfig();

  const [items, setItems] = useState<WorkItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [schemaOpen, setSchemaOpen] = useState(false);
  const [configOpen, setConfigOpen] = useState(false);

  const showConfig = ready && (!config || configOpen);

  const handleLoadByArea = useCallback(
    async (area: string, exact: boolean, excludeStates: string[]) => {
      if (!config) return;
      setLoading(true);
      setError('');
      try {
        const data = await getWorkItemsByArea(config, area, {
          exact,
          excludeStates,
        });
        setItems(data.items);
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
        setItems(loaded);
        setSelectedId(id);
      } catch (exc) {
        setError(exc instanceof Error ? exc.message : String(exc));
      } finally {
        setLoading(false);
      }
    },
    [config],
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
        <LoadPanel
          loading={loading}
          onLoadByArea={handleLoadByArea}
          onLoadById={handleLoadById}
        />
        <TaskGraph
          items={items}
          nodeFields={nodeFields}
          selectedId={selectedId}
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
    </div>
  );
}
