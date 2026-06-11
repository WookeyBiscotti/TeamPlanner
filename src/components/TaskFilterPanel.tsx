import { useMemo } from 'react';
import type { IFilterSet } from '@svar-ui/filter-store';
import { FilterBuilder, FilterQuery, Willow } from '@svar-ui/react-filter';
import '@svar-ui/react-filter/all.css';

import type { FilterEffect, FilterUIMode } from '../types/filters';
import type { WorkItem } from '../types/workItem';
import {
  WORK_ITEM_FILTER_FIELDS,
  buildFilterOptions,
} from '../utils/workItemFilter';

interface TaskFilterPanelProps {
  items: WorkItem[];
  missingChildrenCount: number;
  loading: boolean;
  filterMode: FilterUIMode;
  onFilterModeChange: (mode: FilterUIMode) => void;
  filterValue: IFilterSet | null;
  onFilterChange: (value: IFilterSet | null) => void;
  filterEffect: FilterEffect;
  onFilterEffectChange: (effect: FilterEffect) => void;
  highlightColor: string;
  onHighlightColorChange: (color: string) => void;
  matchedCount: number | null;
  onLoadChildren: () => void;
}

export function TaskFilterPanel({
  items,
  missingChildrenCount,
  loading,
  filterMode,
  onFilterModeChange,
  filterValue,
  onFilterChange,
  filterEffect,
  onFilterEffectChange,
  highlightColor,
  onHighlightColorChange,
  matchedCount,
  onLoadChildren,
}: TaskFilterPanelProps) {
  const options = useMemo(() => buildFilterOptions(items), [items]);

  if (items.length === 0) return null;

  const handleFilterChange = (value: IFilterSet | null) => {
    onFilterChange(value);
  };

  return (
    <section className="filter-panel svar-filter-host">
      <h2>Догрузка и фильтры</h2>

      <div className="filter-actions">
        <button
          type="button"
          className="primary"
          disabled={loading || missingChildrenCount === 0}
          onClick={onLoadChildren}
        >
          {missingChildrenCount > 0
            ? `Догрузить дочерние (${missingChildrenCount})`
            : 'Дочерние загружены'}
        </button>
      </div>

      <div className="filter-mode-tabs">
        <button
          type="button"
          className={filterMode === 'query' ? 'active' : ''}
          onClick={() => onFilterModeChange('query')}
        >
          Строка запроса
        </button>
        <button
          type="button"
          className={filterMode === 'visual' ? 'active' : ''}
          onClick={() => onFilterModeChange('visual')}
        >
          Визуальный
        </button>
      </div>

      <div className="filter-effect-row">
        <label>
          Совпадения
          <select
            value={filterEffect}
            onChange={(event) =>
              onFilterEffectChange(event.target.value as FilterEffect)
            }
          >
            <option value="hide">Скрыть остальные</option>
            <option value="highlight">Жирная обводка</option>
          </select>
        </label>
        {filterEffect === 'highlight' && (
          <label>
            Цвет обводки
            <input
              type="color"
              value={highlightColor}
              onChange={(event) => onHighlightColorChange(event.target.value)}
            />
          </label>
        )}
      </div>

      {matchedCount != null && (
        <p className="muted filter-stats">Совпало с фильтром: {matchedCount}</p>
      )}

      <Willow>
        {filterMode === 'query' ? (
          <FilterQuery
            fields={WORK_ITEM_FILTER_FIELDS}
            options={options as never}
            placeholder='Например: state: Active and areaPath: contains KSN'
            onChange={({ value, error }) => {
              if (error && error.code !== 'NO_DATA') return;
              handleFilterChange(value ?? null);
            }}
          />
        ) : (
          <FilterBuilder
            type="simple"
            fields={WORK_ITEM_FILTER_FIELDS}
            options={options as never}
            value={filterValue ?? undefined}
            onChange={({ value }: { value: IFilterSet }) =>
              handleFilterChange(value ?? null)
            }
          />
        )}
      </Willow>
    </section>
  );
}
