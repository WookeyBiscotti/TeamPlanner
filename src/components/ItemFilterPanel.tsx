import { useState, type FormEvent } from 'react';

import {
  EXCLUSION_RULE_LABELS,
  type ExclusionRule,
  type ExclusionRuleType,
} from '../types/filters';
import { buildExclusionRuleLabel } from '../utils/applyFilters';

interface ItemFilterPanelProps {
  loadedCount: number;
  visibleCount: number;
  rules: ExclusionRule[];
  onAddRule: (rule: ExclusionRule) => void;
  onRemoveRule: (id: string) => void;
  onClearRules: () => void;
}

let ruleCounter = 0;

function nextRuleId(): string {
  ruleCounter += 1;
  return `rule-${Date.now()}-${ruleCounter}`;
}

function parseValues(raw: string): string[] {
  return raw
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean);
}

export function ItemFilterPanel({
  loadedCount,
  visibleCount,
  rules,
  onAddRule,
  onRemoveRule,
  onClearRules,
}: ItemFilterPanelProps) {
  const [ruleType, setRuleType] = useState<ExclusionRuleType>('status');
  const [ruleValues, setRuleValues] = useState('');

  if (loadedCount === 0) return null;

  const handleSubmit = (event: FormEvent) => {
    event.preventDefault();
    const values = parseValues(ruleValues);
    if (values.length === 0) return;

    onAddRule({
      id: nextRuleId(),
      type: ruleType,
      values,
      label: buildExclusionRuleLabel(ruleType, values),
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
  };

  return (
    <section className="filter-panel">
      <h2>Скрыть задачи</h2>
      <p className="muted filter-stats">
        Загружено: {loadedCount} · На графе: {visibleCount}
      </p>

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

        <label>
          Значения (через запятую)
          <input
            value={ruleValues}
            onChange={(event) => setRuleValues(event.target.value)}
            placeholder={placeholderByType[ruleType]}
          />
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
                <span>{EXCLUSION_RULE_LABELS[rule.type]}: {rule.values.join(', ')}</span>
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
