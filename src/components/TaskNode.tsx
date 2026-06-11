import type { CSSProperties, MouseEvent } from 'react';
import { Handle, Position, type NodeProps } from '@xyflow/react';

import { fieldDisplayValue } from '../api/tfs';
import { getWorkItemDescription } from '../utils/workItemFilter';
import { getStatusColor } from '../utils/statusColors';
import type { TaskNodeData } from '../utils/buildGraph';

function nodeSurfaceStyle(
  colorByStatus: boolean,
  statusColor: string,
  highlightColor: string | null,
): CSSProperties {
  const style: Record<string, string> = {};

  if (colorByStatus) {
    style['--node-status-color'] = statusColor;
    style['--node-bg'] = `color-mix(in srgb, ${statusColor} 28%, #ffffff)`;
    style['--node-border'] = statusColor;
    style['--node-text'] = '#0f172a';
  }

  if (highlightColor) {
    style['--filter-highlight-color'] = highlightColor;
  }

  return style as CSSProperties;
}

export function TaskNode({ data, selected }: NodeProps) {
  const nodeData = data as TaskNodeData;
  const {
    item,
    fields,
    colorByStatus,
    statusColors,
    expanded,
    highlightColor,
    onToggleExpand,
    onShowRaw,
  } = nodeData;

  const titleField = fields.find((field) => field.key === 'System.Title');
  const otherFields = fields.filter((field) => field.key !== 'System.Title');
  const statusColor = getStatusColor(item.fields['System.State'], statusColors);
  const description = getWorkItemDescription(item);

  const handleBodyClick = () => {
    onToggleExpand?.(item.id);
  };

  const handleRawClick = (event: MouseEvent<HTMLButtonElement>) => {
    event.stopPropagation();
    onShowRaw?.(item.id);
  };

  return (
    <div
      className={[
        'task-node',
        selected ? 'selected' : '',
        colorByStatus ? 'color-by-status' : '',
        highlightColor ? 'filter-highlight' : '',
        expanded ? 'expanded' : '',
      ]
        .filter(Boolean)
        .join(' ')}
      style={nodeSurfaceStyle(colorByStatus, statusColor, highlightColor)}
    >
      <Handle type="target" position={Position.Top} />
      <div className="task-node-toolbar">
        <button
          type="button"
          className="ghost tiny task-node-raw-btn"
          title="Сырые данные"
          onClick={handleRawClick}
        >
          {'{…}'}
        </button>
      </div>
      <div className="task-node-body" onClick={handleBodyClick} role="presentation">
        {titleField ? (
          <div className="task-node-title">
            {fieldDisplayValue(item.fields, titleField.key)}
          </div>
        ) : (
          <div className="task-node-title">#{item.id}</div>
        )}
        {otherFields.map((field) => (
          <div key={field.key} className="task-node-row">
            <span className="task-node-label">{field.label}</span>
            <span className="task-node-value">
              {fieldDisplayValue(item.fields, field.key)}
            </span>
          </div>
        ))}
        {expanded && (
          <div className="task-node-description">
            <div className="task-node-description-label">Описание</div>
            <div className="task-node-description-text">
              {description || '—'}
            </div>
          </div>
        )}
      </div>
      <Handle type="source" position={Position.Bottom} />
    </div>
  );
}
