import { useState, type FormEvent } from 'react';

interface LoadPanelProps {
  loading: boolean;
  onLoadByArea: (area: string, exact: boolean, excludeStates: string[]) => void;
  onLoadById: (id: number) => void;
}

export function LoadPanel({ loading, onLoadByArea, onLoadById }: LoadPanelProps) {
  const [area, setArea] = useState('');
  const [exact, setExact] = useState(false);
  const [excludeStates, setExcludeStates] = useState('Closed, Removed');
  const [itemId, setItemId] = useState('');

  const handleAreaSubmit = (event: FormEvent) => {
    event.preventDefault();
    const trimmed = area.trim();
    if (!trimmed) return;
    const states = excludeStates
      .split(',')
      .map((value) => value.trim())
      .filter(Boolean);
    onLoadByArea(trimmed, exact, states);
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
          Исключить статусы (через запятую)
          <input
            value={excludeStates}
            onChange={(e) => setExcludeStates(e.target.value)}
            placeholder="Closed, Removed"
            disabled={loading}
          />
        </label>

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
