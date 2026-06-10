import type { CSSProperties } from 'react';
import { Handle, Position, type NodeProps } from '@xyflow/react';

import { fieldDisplayValue } from '../api/tfs';
import { getStatusColor } from '../utils/statusColors';
import type { TaskNodeData } from '../utils/buildGraph';

function nodeSurfaceStyle(
  colorByStatus: boolean,
  statusColor: string,
): CSSProperties {
  if (!colorByStatus) {
    return {};
  }
  return {
    '--node-status-color': statusColor,
    '--node-bg': `color-mix(in srgb, ${statusColor} 28%, #ffffff)`,
    '--node-border': statusColor,
    '--node-text': '#0f172a',
  } as CSSProperties;
}

export function TaskNode({ data, selected }: NodeProps) {
  const nodeData = data as TaskNodeData;
  const { item, fields, colorByStatus, statusColors } = nodeData;
  const titleField = fields.find((field) => field.key === 'System.Title');
  const otherFields = fields.filter((field) => field.key !== 'System.Title');
  const statusColor = getStatusColor(item.fields['System.State'], statusColors);

  return (
    <div
      className={`task-node${selected ? ' selected' : ''}${colorByStatus ? ' color-by-status' : ''}`}
      style={nodeSurfaceStyle(colorByStatus, statusColor)}
    >
      <Handle type="target" position={Position.Top} />
      <div className="task-node-body">
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
      </div>
      <Handle type="source" position={Position.Bottom} />
    </div>
  );
}
