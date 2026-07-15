interface SkeletonProps {
  variant?: 'text' | 'title' | 'card' | 'avatar' | 'custom';
  width?: string;
  height?: string;
  count?: number;
  className?: string;
}

function LoadingSkeleton({ variant = 'text', width, height, count = 1, className = '' }: SkeletonProps) {
  const items = Array.from({ length: count });

  const getClass = () => {
    if (className) return `skeleton ${className}`;
    return `skeleton skeleton--${variant}`;
  };

  const getStyle = (): React.CSSProperties => {
    if (variant === 'custom') {
      return {
        width: width || '100%',
        height: height || '20px',
      };
    }
    return {};
  };

  return (
    <>
      {items.map((_, i) => (
        <div
          key={i}
          className={getClass()}
          style={{
            ...getStyle(),
            marginBottom: i < count - 1 ? (variant === 'card' ? '12px' : '8px') : 0,
          }}
        />
      ))}
    </>
  );
}

export default LoadingSkeleton;
