import { describe, it, expect, beforeEach, vi } from 'vitest';
import fs from 'fs';
import path from 'path';

describe('Payment Processing Contract', () => {
  // Read the contract code
  const contractCode = fs.readFileSync(
      path.resolve(__dirname, '../contracts/payment-processing.clar'),
      'utf8'
  );
  
  // Simple parser to extract function names and parameters
  const extractFunctions = (code) => {
    const functionRegex = /$$define-(?:public|read-only)\s+\(([^$$]+)/g;
    const matches = [...code.matchAll(functionRegex)];
    return matches.map(match => {
      const parts = match[1].split(' ');
      return {
        name: parts[0],
        params: parts.slice(1)
      };
    });
  };
  
  const functions = extractFunctions(contractCode);
  
  it('should have the required public functions', () => {
    const functionNames = functions.map(f => f.name);
    
    expect(functionNames).toContain('process-payment');
    expect(functionNames).toContain('execute-payment');
    expect(functionNames).toContain('fund-contract');
    expect(functionNames).toContain('get-payment');
    expect(functionNames).toContain('get-contract-balance');
  });
  
  it('process-payment should have the correct parameters', () => {
    const processPayment = functions.find(f => f.name === 'process-payment');
    
    expect(processPayment.params.length).toBe(1);
    expect(processPayment.params).toContain('claim-id');
  });
  
  it('execute-payment should have the correct parameters', () => {
    const executePayment = functions.find(f => f.name === 'execute-payment');
    
    expect(executePayment.params.length).toBe(2);
    expect(executePayment.params).toContain('payment-id');
    expect(executePayment.params).toContain('tx-hash');
  });
  
  it('should have a payments map defined', () => {
    expect(contractCode).toContain('(define-map payments');
  });
  
  it('should have contract balance tracking', () => {
    expect(contractCode).toContain('(define-data-var contract-balance uint');
  });
  
  it('should check claim verification before processing payment', () => {
    expect(contractCode).toContain('(contract-call? .verification is-verified claim-id)');
  });
});
