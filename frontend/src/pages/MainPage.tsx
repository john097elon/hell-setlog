import { useState } from 'react';
import PartyPanel from '../components/panels/PartyPanel';
import WorkoutPanel from '../components/panels/WorkoutPanel';
import RecordsPanel from '../components/panels/RecordsPanel';

function MainPage() {
  const [selectedPartyId, setSelectedPartyId] = useState<string | null>(null);
  const [recordsKey, setRecordsKey] = useState(0);

  return (
    <div style={{
      display: 'flex',
      height: '100%',
      overflow: 'hidden',
    }}>
      {/* Left: Party */}
      <aside style={{
        width: '256px',
        flexShrink: 0,
        borderRight: '1px solid var(--color-border-subtle)',
        display: 'flex',
        flexDirection: 'column',
        overflow: 'hidden',
      }}>
        <PartyPanel
          selectedPartyId={selectedPartyId}
          onSelectParty={setSelectedPartyId}
        />
      </aside>

      {/* Center: Workout */}
      <main style={{
        flex: 1,
        minWidth: 0,
        display: 'flex',
        flexDirection: 'column',
        overflow: 'hidden',
        borderRight: '1px solid var(--color-border-subtle)',
      }}>
        <WorkoutPanel
          partyId={selectedPartyId}
          onWorkoutEnded={() => setRecordsKey(k => k + 1)}
        />
      </main>

      {/* Right: Records */}
      <aside style={{
        width: '280px',
        flexShrink: 0,
        display: 'flex',
        flexDirection: 'column',
        overflow: 'hidden',
      }}>
        <RecordsPanel refreshKey={recordsKey} />
      </aside>
    </div>
  );
}

export default MainPage;
