import { Handle, Position, type NodeProps } from '@xyflow/react';

import { fieldDisplayValue } from '../api/tfs';
import type { TaskNodeData } from '../utils/buildGraph';

export function TaskNode({ data, selected }: NodeProps) {
  const nodeData = data as TaskNodeData;
  const { item, fields } = nodeData;
  const titleField = fields.find((field) => field.key === 'System.Title');
  const otherFields = fields.filter((field) => field.key !== 'System.Title');

  return (
    <div className={`task-node${selected ? ' selected' : ''}`}>
      <Handle type="target" position={Position.Top} />
      <div className="task-node-accent" />
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
