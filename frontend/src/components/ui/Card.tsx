import type { HTMLAttributes, ReactNode } from 'react';

interface CardProps extends HTMLAttributes<HTMLDivElement> {
  children: ReactNode;
  accent?: boolean;
}

function Card({ children, accent = false, className = '', ...props }: CardProps) {
  const classes = ['ui-card', accent ? 'ui-card--accent' : '', className].filter(Boolean).join(' ');

  return (
    <div className={classes} {...props}>
      {children}
    </div>
  );
}

export default Card;
