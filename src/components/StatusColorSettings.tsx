import { useEffect, useMemo, useState } from 'react';

import type { WorkItem } from '../types/workItem';
import {
  DEFAULT_STATUS_COLORS,
  collectStatuses,
  getStatusColor,
} from '../utils/statusColors';

interface StatusColorSettingsProps {
  open: boolean;
  items: WorkItem[];
  colorByStatus: boolean;
  statusColors: Record<string, string>;
  onColorByStatusChange: (value: boolean) => void;
  onStatusColorsChange: (colors: Record<string, string>) => void;
  onClose: () => void;
}

export function StatusColorSettings({
  open,
  items,
  colorByStatus,
  statusColors,
  onColorByStatusChange,
  onStatusColorsChange,
  onClose,
}: StatusColorSettingsProps) {
  const [draft, setDraft] = useState(statusColors);

  const statuses = useMemo(() => {
    const fromItems = collectStatuses(items);
    const known = Object.keys(DEFAULT_STATUS_COLORS);
    return [...new Set([...known, ...fromItems])].sort((a, b) =>
      a.localeCompare(b, 'ru'),
    );
  }, [items]);

  useEffect(() => {
    if (open) setDraft(statusColors);
  }, [open, statusColors]);

  if (!open) return null;

  const handleColorChange = (status: string, color: string) => {
    setDraft((prev) => ({ ...prev, [status]: color }));
  };

  const handleReset = () => {
    setDraft({});
    onStatusColorsChange({});
  };

  const handleSave = () => {
    onStatusColorsChange(draft);
    onClose();
  };

  return (
    <div className="modal-backdrop" role="dialog" aria-modal="true">
      <div className="modal-card modal-card-wide">
        <div className="modal-header">
          <h2>Цвета по статусу</h2>
          <button type="button" className="ghost" onClick={onClose}>
            Закрыть
          </button>
        </div>

        <label className="checkbox-row">
          <input
            type="checkbox"
            checked={colorByStatus}
            onChange={(event) => onColorByStatusChange(event.target.checked)}
          />
          Раскрашивать ноды по статусу задачи
        </label>

        <div className="status-color-list">
          {statuses.map((status) => {
            const color = getStatusColor(status, { ...draft });
            const custom = draft[status] ?? '';
            return (
              <div key={status} className="status-color-row">
                <span
                  className="status-color-preview"
                  style={{ background: color }}
                  title={status}
                />
                <span className="status-color-name">{status}</span>
                <input
                  type="color"
                  value={custom || DEFAULT_STATUS_COLORS[status] || '#cbd5e1'}
                  onChange={(event) => handleColorChange(status, event.target.value)}
                  disabled={!colorByStatus}
                />
                <button
                  type="button"
                  className="ghost tiny"
                  disabled={!colorByStatus || !(status in draft)}
                  onClick={() => {
                    setDraft((prev) => {
                      const next = { ...prev };
                      delete next[status];
                      return next;
                    });
                  }}
                >
                  сброс
                </button>
              </div>
            );
          })}
        </div>

        <div className="modal-actions">
          <button type="button" className="ghost" onClick={handleReset}>
            Сбросить все
          </button>
          <button type="button" className="primary" onClick={handleSave}>
            Сохранить
          </button>
        </div>
      </div>
    </div>
  );
}
