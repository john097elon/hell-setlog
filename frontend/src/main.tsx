import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import App from './App';
import PWAUpdatePrompt from './pwa/PWAUpdatePrompt';
import OfflineDetect from './pwa/OfflineDetect';
import './index.css';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <BrowserRouter>
      <App />
      <PWAUpdatePrompt />
      <OfflineDetect />
    </BrowserRouter>
  </React.StrictMode>,
);
