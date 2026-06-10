import { AVAILABLE_NODE_FIELDS, type TNodeField } from '../types/workItem';

interface FieldSchemaSettingsProps {
  open: boolean;
  selected: TNodeField[];
  onChange: (fields: TNodeField[]) => void;
  onClose: () => void;
}

export function FieldSchemaSettings({
  open,
  selected,
  onChange,
  onClose,
}: FieldSchemaSettingsProps) {
  if (!open) return null;

  const selectedKeys = new Set(selected.map((field) => field.key));

  const toggle = (field: TNodeField) => {
    if (selectedKeys.has(field.key)) {
      const next = selected.filter((item) => item.key !== field.key);
      if (next.length > 0) onChange(next);
      return;
    }
    onChange([...selected, field]);
  };

  const move = (index: number, delta: number) => {
    const next = [...selected];
    const target = index + delta;
    if (target < 0 || target >= next.length) return;
    [next[index], next[target]] = [next[target], next[index]];
    onChange(next);
  };

  return (
    <div className="modal-backdrop" role="dialog" aria-modal="true">
      <div className="modal-card modal-card-wide">
        <div className="modal-header">
          <h2>Схема полей в ноде</h2>
          <button type="button" className="ghost" onClick={onClose}>
            Закрыть
          </button>
        </div>

        <div className="schema-grid">
          <section>
            <h3>Доступные поля</h3>
            <ul className="field-list">
              {AVAILABLE_NODE_FIELDS.map((field) => (
                <li key={field.key}>
                  <label>
                    <input
                      type="checkbox"
                      checked={selectedKeys.has(field.key)}
                      onChange={() => toggle(field)}
                    />
                    <span>{field.label}</span>
                    <code>{field.key}</code>
                  </label>
                </li>
              ))}
            </ul>
          </section>

          <section>
            <h3>Порядок отображения</h3>
            <ol className="order-list">
              {selected.map((field, index) => (
                <li key={field.key}>
                  <span>{field.label}</span>
                  <div className="order-actions">
                    <button
                      type="button"
                      className="ghost"
                      onClick={() => move(index, -1)}
                      disabled={index === 0}
                    >
                      ↑
                    </button>
                    <button
                      type="button"
                      className="ghost"
                      onClick={() => move(index, 1)}
                      disabled={index === selected.length - 1}
                    >
                      ↓
                    </button>
                  </div>
                </li>
              ))}
            </ol>
          </section>
        </div>
      </div>
    </div>
  );
}
