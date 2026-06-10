import type { CSSProperties } from 'react';

import {
  ALL_EDGE_KINDS,
  RELATION_TYPES,
  type EdgeKind,
} from '../types/workItem';

interface LinkFilterProps {
  visible: Set<EdgeKind>;
  onChange: (visible: Set<EdgeKind>) => void;
  edgeCounts: Partial<Record<EdgeKind, number>>;
}

export function LinkFilter({ visible, onChange, edgeCounts }: LinkFilterProps) {
  const toggle = (kind: EdgeKind) => {
    const next = new Set(visible);
    if (next.has(kind)) {
      if (next.size > 1) next.delete(kind);
    } else {
      next.add(kind);
    }
    onChange(next);
  };

  const selectAll = () => onChange(new Set(ALL_EDGE_KINDS));
  const selectNone = () => {
    const first = ALL_EDGE_KINDS[0];
    if (first) onChange(new Set([first]));
  };

  return (
    <div className="link-filter">
      <div className="link-filter-header">
        <span className="link-filter-title">Связи</span>
        <div className="link-filter-actions">
          <button type="button" className="ghost tiny" onClick={selectAll}>
            все
          </button>
          <button type="button" className="ghost tiny" onClick={selectNone}>
            сброс
          </button>
        </div>
      </div>
      <div className="link-filter-list">
        {RELATION_TYPES.map((type) => {
          const count = edgeCounts[type.kind] ?? 0;
          const active = visible.has(type.kind);
          return (
            <label
              key={type.kind}
              className={`link-filter-item${active ? ' active' : ''}`}
              style={{ '--link-color': type.color } as CSSProperties}
            >
              <input
                type="checkbox"
                checked={active}
                onChange={() => toggle(type.kind)}
              />
              <span className="link-filter-swatch" />
              <span className="link-filter-label">{type.label}</span>
              <span className="link-filter-count">{count}</span>
            </label>
          );
        })}
      </div>
    </div>
  );
}
