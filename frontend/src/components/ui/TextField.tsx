import type { InputHTMLAttributes } from 'react';

interface TextFieldProps extends InputHTMLAttributes<HTMLInputElement> {
  label: string;
  wrapperClassName?: string;
}

function TextField({ label, id, wrapperClassName = '', className = '', ...props }: TextFieldProps) {
  const inputId = id ?? props.name ?? label;

  return (
    <label className={['ui-text-field', wrapperClassName].filter(Boolean).join(' ')} htmlFor={inputId}>
      <span className="ui-text-field__label">{label}</span>
      <input id={inputId} className={['ui-text-field__input', className].filter(Boolean).join(' ')} {...props} />
    </label>
  );
}

export default TextField;
