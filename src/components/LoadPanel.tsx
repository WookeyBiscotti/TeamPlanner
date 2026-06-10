import { useState, type FormEvent } from 'react';

import type { AreaLoadQuery } from '../types/filters';

interface LoadPanelProps {
  loading: boolean;
  onLoadByArea: (query: AreaLoadQuery) => void;
  onLoadById: (id: number) => void;
}

function parseList(input: string): string[] {
  return input
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean);
}

export function LoadPanel({ loading, onLoadByArea, onLoadById }: LoadPanelProps) {
  const [area, setArea] = useState('');
  const [exact, setExact] = useState(false);
  const [excludeStates, setExcludeStates] = useState('Closed, Removed');
  const [includeStates, setIncludeStates] = useState('');
  const [includeTags, setIncludeTags] = useState('');
  const [itemId, setItemId] = useState('');

  const handleAreaSubmit = (event: FormEvent) => {
    event.preventDefault();
    const trimmed = area.trim();
    if (!trimmed) return;
    onLoadByArea({
      area: trimmed,
      exact,
      excludeStates: parseList(excludeStates),
      includeStates: parseList(includeStates),
      includeTags: parseList(includeTags),
    });
  };

  const handleIdSubmit = (event: FormEvent) => {
    event.preventDefault();
    const id = Number.parseInt(itemId.trim(), 10);
    if (!Number.isFinite(id)) return;
    onLoadById(id);
  };

  return (
    <aside className="load-panel">
      <h2>Загрузка задач</h2>

      <form onSubmit={handleAreaSubmit}>
        <label>
          System.AreaPath
          <input
            value={area}
            onChange={(e) => setArea(e.target.value)}
            placeholder="IResearch\KSN-AMR"
            disabled={loading}
          />
        </label>

        <label className="checkbox-row">
          <input
            type="checkbox"
            checked={exact}
            onChange={(e) => setExact(e.target.checked)}
            disabled={loading}
          />
          Только точное совпадение Area
        </label>

        <label>
          Только со статусами (через запятую)
          <input
            value={includeStates}
            onChange={(e) => setIncludeStates(e.target.value)}
            placeholder="Active, New"
            disabled={loading}
          />
        </label>

        <label>
          Только с тегами (через запятую, любой из)
          <input
            value={includeTags}
            onChange={(e) => setIncludeTags(e.target.value)}
            placeholder="sprint-42, urgent"
            disabled={loading}
          />
        </label>

        <label>
          Исключить статусы (через запятую)
          <input
            value={excludeStates}
            onChange={(e) => setExcludeStates(e.target.value)}
            placeholder="Closed, Removed"
            disabled={loading || includeStates.trim().length > 0}
          />
        </label>
        {includeStates.trim().length > 0 && (
          <p className="field-hint">Исключение статусов не применяется, когда задан список «только со статусами».</p>
        )}

        <button type="submit" className="primary" disabled={loading}>
          Загрузить по Area
        </button>
      </form>

      <hr />

      <form onSubmit={handleIdSubmit}>
        <label>
          ID work item
          <input
            value={itemId}
            onChange={(e) => setItemId(e.target.value)}
            placeholder="12345"
            disabled={loading}
          />
        </label>
        <button type="submit" disabled={loading}>
          Загрузить одну задачу
        </button>
      </form>
    </aside>
  );
}
