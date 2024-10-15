import React from 'react';
import { functions } from '@/lib/functions';

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

  const MAX_DESCRIPTION_LENGTH = 60;

  return (
    <button
      onClick={() => executeFunction(functionName)}
      className="group w-full max-w-xs p-3 text-left bg-transparent border border-gray-200 dark:border-gray-800 rounded-lg transition-all duration-200 hover:bg-gray-50 dark:hover:bg-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
    >
      <span className="block text-sm font-medium text-gray-900 dark:text-gray-100 mb-1 group-hover:text-blue-600 dark:group-hover:text-blue-400">
        {functionInfo.name}
      </span>
      <span className="block text-xs text-gray-500 dark:text-gray-400">
        {functionInfo.description.length > MAX_DESCRIPTION_LENGTH 
          ? `${functionInfo.description.slice(0, MAX_DESCRIPTION_LENGTH)}...` 
          : functionInfo.description}
      </span>
    </button>
  );
};

export default FunctionButton;
