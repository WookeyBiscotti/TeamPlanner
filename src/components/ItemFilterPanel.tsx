import { useState, type FormEvent } from 'react';

import {
  AREA_PATH_MATCH_LABELS,
  EXCLUSION_RULE_LABELS,
  type AreaPathMatch,
  type ExclusionRule,
  type ExclusionRuleType,
} from '../types/filters';
import { buildExclusionRuleLabel } from '../utils/applyFilters';

interface ItemFilterPanelProps {
  loadedCount: number;
  visibleCount: number;
  missingChildrenCount: number;
  loading: boolean;
  rules: ExclusionRule[];
  onAddRule: (rule: ExclusionRule) => void;
  onRemoveRule: (id: string) => void;
  onClearRules: () => void;
  onLoadChildren: () => void;
}

let ruleCounter = 0;

function nextRuleId(): string {
  ruleCounter += 1;
  return `rule-${Date.now()}-${ruleCounter}`;
}

function parseValues(raw: string, type: ExclusionRuleType): string[] {
  if (type === 'areaPath') {
    return raw
      .split('\n')
      .map((value) => value.trim())
      .filter(Boolean);
  }
  return raw
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean);
}

export function ItemFilterPanel({
  loadedCount,
  visibleCount,
  missingChildrenCount,
  loading,
  rules,
  onAddRule,
  onRemoveRule,
  onClearRules,
  onLoadChildren,
}: ItemFilterPanelProps) {
  const [ruleType, setRuleType] = useState<ExclusionRuleType>('status');
  const [ruleValues, setRuleValues] = useState('');
  const [areaMatch, setAreaMatch] = useState<AreaPathMatch>('under');

  if (loadedCount === 0) return null;

  const handleSubmit = (event: FormEvent) => {
    event.preventDefault();
    const values = parseValues(ruleValues, ruleType);
    if (values.length === 0) return;

    onAddRule({
      id: nextRuleId(),
      type: ruleType,
      values,
      label: buildExclusionRuleLabel(ruleType, values),
      areaMatch: ruleType === 'areaPath' ? areaMatch : undefined,
    });
    setRuleValues('');
  };

  const placeholderByType: Record<ExclusionRuleType, string> = {
    status: 'Closed, Removed',
    parent: '12345, 67890',
    parentSubtree: '12345',
    tag: 'blocked, urgent',
    workItemType: 'Bug, Task',
    id: '12345',
    areaPath: 'IResearch\\KSN-AMR',
  };

  const valuesLabel =
    ruleType === 'areaPath'
      ? 'Area Path (по одному на строку)'
      : 'Значения (через запятую)';

  return (
    <section className="filter-panel">
      <h2>Догрузка и фильтры</h2>
      <p className="muted filter-stats">
        Загружено: {loadedCount} · На графе: {visibleCount}
      </p>

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
        <p className="field-hint">
          Подтянет прямых потомков из связей задач, которых нет в текущей загрузке.
          Нажимайте повторно для следующего уровня.
        </p>
      </div>

      <h3 className="filter-subtitle">Скрыть задачи</h3>

      <form onSubmit={handleSubmit} className="filter-form">
        <label>
          Критерий
          <select
            value={ruleType}
            onChange={(event) => setRuleType(event.target.value as ExclusionRuleType)}
          >
            {(Object.keys(EXCLUSION_RULE_LABELS) as ExclusionRuleType[]).map((type) => (
              <option key={type} value={type}>
                {EXCLUSION_RULE_LABELS[type]}
              </option>
            ))}
          </select>
        </label>

        {ruleType === 'areaPath' && (
          <label>
            Совпадение Area
            <select
              value={areaMatch}
              onChange={(event) => setAreaMatch(event.target.value as AreaPathMatch)}
            >
              {(Object.keys(AREA_PATH_MATCH_LABELS) as AreaPathMatch[]).map((mode) => (
                <option key={mode} value={mode}>
                  {AREA_PATH_MATCH_LABELS[mode]}
                </option>
              ))}
            </select>
          </label>
        )}

        <label>
          {valuesLabel}
          {ruleType === 'areaPath' ? (
            <textarea
              rows={3}
              value={ruleValues}
              onChange={(event) => setRuleValues(event.target.value)}
              placeholder={placeholderByType[ruleType]}
            />
          ) : (
            <input
              value={ruleValues}
              onChange={(event) => setRuleValues(event.target.value)}
              placeholder={placeholderByType[ruleType]}
            />
          )}
        </label>

        <button type="submit" className="primary">
          Скрыть
        </button>
      </form>

      {rules.length > 0 && (
        <div className="filter-rules">
          <div className="filter-rules-header">
            <span>Активные правила</span>
            <button type="button" className="ghost tiny" onClick={onClearRules}>
              очистить
            </button>
          </div>
          <ul>
            {rules.map((rule) => (
              <li key={rule.id}>
                <span>
                  {EXCLUSION_RULE_LABELS[rule.type]}
                  {rule.type === 'areaPath' && rule.areaMatch
                    ? ` (${AREA_PATH_MATCH_LABELS[rule.areaMatch]})`
                    : ''}
                  : {rule.values.join(', ')}
                </span>
                <button
                  type="button"
                  className="ghost tiny"
                  onClick={() => onRemoveRule(rule.id)}
                  aria-label="Удалить правило"
                >
                  ×
                </button>
              </li>
            ))}
          </ul>
        </div>
      )}
    </section>
  );
}
