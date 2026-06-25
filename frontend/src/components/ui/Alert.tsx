import type { HTMLAttributes, ReactNode } from 'react';

interface AlertProps extends HTMLAttributes<HTMLDivElement> {
  children: ReactNode;
  variant?: 'danger' | 'success';
}

function Alert({ children, variant = 'danger', className = '', role = 'alert', ...props }: AlertProps) {
  const classes = ['ui-alert', `ui-alert--${variant}`, className].filter(Boolean).join(' ');

  return (
    <div className={classes} role={role} {...props}>
      {children}
    </div>
  );
}

export default Alert;
