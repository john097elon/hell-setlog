import type { CSSProperties, HTMLAttributes, ReactNode } from 'react';

interface PageShellProps extends HTMLAttributes<HTMLDivElement> {
  children: ReactNode;
  maxWidth?: number | string;
  centered?: boolean;
}

function PageShell({ children, maxWidth, centered = false, className = '', style, ...props }: PageShellProps) {
  const classes = ['ui-page-shell', centered ? 'ui-page-shell--centered' : '', className].filter(Boolean).join(' ');
  const maxWidthStyle = maxWidth ? ({ '--page-shell-max-width': typeof maxWidth === 'number' ? `${maxWidth}px` : maxWidth } as CSSProperties) : {};

  return (
    <div className={classes} style={{ ...maxWidthStyle, ...style }} {...props}>
      {children}
    </div>
  );
}

export default PageShell;
