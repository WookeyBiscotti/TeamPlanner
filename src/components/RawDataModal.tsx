import type { WorkItem } from '../types/workItem';

interface RawDataModalProps {
  item: WorkItem | null;
  onClose: () => void;
}

export function RawDataModal({ item, onClose }: RawDataModalProps) {
  if (!item) return null;

  return (
    <div className="modal-backdrop" role="dialog" aria-modal="true" onClick={onClose}>
      <div
        className="modal-card modal-card-wide raw-data-modal"
        onClick={(event) => event.stopPropagation()}
      >
        <div className="modal-header">
          <h2>Сырые данные #{item.id}</h2>
          <button type="button" className="ghost" onClick={onClose}>
            Закрыть
          </button>
        </div>
        <pre className="raw-data-pre">{JSON.stringify(item, null, 2)}</pre>
      </div>
    </div>
  );
}
