import React from 'react';
import { functions } from '../../src/lib/functions';

interface FunctionButtonProps {
  functionName: string;
  executeFunction: (functionName: string) => void;
}

const FunctionButton: React.FC<FunctionButtonProps> = ({
  functionName,
  executeFunction,
}) => {
  const functionInfo = functions[functionName];

  if (!functionInfo) {
    return null;
  }

  // Define a maximum length for the description before truncation
  const MAX_DESCRIPTION_LENGTH = 50;

  return (
    <button
      onClick={() => executeFunction(functionName)}
      className="flex-1 min-w-[150px] max-w-[300px] h-auto px-4 py-2 bg-transparent text-black dark:text-white border border-white/20 rounded-md hover:bg-white/10 transition-colors flex flex-col items-start justify-center"
    >
      <span className="font-medium">{functionInfo.name}</span>
      <span className="text-xs text-black/60 dark:text-white/60 mt-1">
        {functionInfo.description.length > MAX_DESCRIPTION_LENGTH 
          ? `${functionInfo.description.slice(0, MAX_DESCRIPTION_LENGTH)}...` 
          : functionInfo.description}
      </span>
    </button>
  );
};

export default FunctionButton;
