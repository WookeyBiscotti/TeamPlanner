import { LAYOUT_OPTIONS, type LayoutAlgorithm } from '../types/layout';

interface LayoutSelectorProps {
  value: LayoutAlgorithm;
  onChange: (value: LayoutAlgorithm) => void;
}

export function LayoutSelector({ value, onChange }: LayoutSelectorProps) {
  const current = LAYOUT_OPTIONS.find((option) => option.id === value);

  return (
    <div className="layout-selector">
      <label>
        Расположение
        <select
          value={value}
          onChange={(event) => onChange(event.target.value as LayoutAlgorithm)}
        >
          {LAYOUT_OPTIONS.map((option) => (
            <option key={option.id} value={option.id}>
              {option.label}
            </option>
          ))}
        </select>
      </label>
      {current && <span className="layout-hint">{current.description}</span>}
    </div>
  );
}
