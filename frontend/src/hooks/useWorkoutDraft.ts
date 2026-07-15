import { useState, useEffect, useCallback } from 'react';

const DRAFT_KEY = 'workout_draft';

interface WorkoutDraft {
  partyId: string;
  notes: string;
  savedAt: number;
}

/**
 * Persist and recover workout draft fields across page refreshes.
 */
export function useWorkoutDraft() {
  const [draft, setDraft] = useState<WorkoutDraft>(() => {
    try {
      const raw = localStorage.getItem(DRAFT_KEY);
      if (raw) return JSON.parse(raw) as WorkoutDraft;
    } catch { /* ignore */ }
    return { partyId: '', notes: '', savedAt: 0 };
  });

  // Auto-save to localStorage whenever values change
  useEffect(() => {
    const payload = { ...draft, savedAt: Date.now() };
    localStorage.setItem(DRAFT_KEY, JSON.stringify(payload));
  }, [draft]);

  const updateDraft = useCallback((partial: Partial<WorkoutDraft>) => {
    setDraft((prev) => ({ ...prev, ...partial }));
  }, []);

  const clearDraft = useCallback(() => {
    localStorage.removeItem(DRAFT_KEY);
    setDraft({ partyId: '', notes: '', savedAt: 0 });
  }, []);

  const hasDraft = draft.savedAt > 0 && (draft.partyId !== '' || draft.notes !== '');

  return { draft, updateDraft, clearDraft, hasDraft };
}
