import { useEffect, useState, type FormEvent } from 'react';

import type { TfsConfig } from '../api/tfs';

interface ConfigDialogProps {
  open: boolean;
  initial?: TfsConfig | null;
  onSave: (config: TfsConfig) => void;
}

export function ConfigDialog({ open, initial, onSave }: ConfigDialogProps) {
  const [baseUrl, setBaseUrl] = useState(initial?.baseUrl ?? '');
  const [pat, setPat] = useState(initial?.pat ?? '');
  const [error, setError] = useState('');

  useEffect(() => {
    if (open) {
      setBaseUrl(initial?.baseUrl ?? '');
      setPat(initial?.pat ?? '');
      setError('');
    }
  }, [open, initial?.baseUrl, initial?.pat]);

  if (!open) return null;

  const handleSubmit = (event: FormEvent) => {
    event.preventDefault();
    const trimmedUrl = baseUrl.trim();
    const trimmedPat = pat.trim();
    if (!trimmedUrl || !trimmedPat) {
      setError('Укажите Base URL и Personal Access Token');
      return;
    }
    setError('');
    onSave({ baseUrl: trimmedUrl, pat: trimmedPat });
  };

  return (
    <div className="modal-backdrop" role="dialog" aria-modal="true">
      <form className="modal-card" onSubmit={handleSubmit}>
        <h2>Подключение к TFS / Azure DevOps</h2>
        <p className="muted">
          Ключ и URL сохраняются только в localStorage вашего браузера.
        </p>

        <label>
          Base URL
          <input
            type="url"
            value={baseUrl}
            onChange={(e) => setBaseUrl(e.target.value)}
            placeholder="https://dev.azure.com/org/project"
            autoFocus
            required
          />
        </label>

        <label>
          Personal Access Token
          <input
            type="password"
            value={pat}
            onChange={(e) => setPat(e.target.value)}
            placeholder="PAT с правами Work Items (Read)"
            required
          />
        </label>

        {error && <p className="error">{error}</p>}

        <button type="submit" className="primary">
          Сохранить и продолжить
        </button>
      </form>
    </div>
  );
}
