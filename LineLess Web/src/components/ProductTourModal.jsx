import { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Pause, Play, RotateCcw } from 'lucide-react';
import sceneMenu from '../assets/tutorial_cust_menu.png';
import sceneDashboard from '../assets/tutorial_dashboard.png';
import sceneManage from '../assets/tutorial_menu.png';
import sceneReports from '../assets/tutorial_reports.png';
import sceneConfirm from '../assets/tutorial_cust_confirmed.png';

// A lightweight, auto-playing 15-second product tour (5 scenes x 3s) that
// showcases the app's features when the user clicks "Watch Product Tour".
const SCENE_MS = 3000;
const SCENES = [
  { img: sceneMenu, tag: 'Step 1', title: 'Scan & Order', desc: 'Customers scan a QR code and order right from their phone — no app download needed.' },
  { img: sceneDashboard, tag: 'Step 2', title: 'Live Dashboard', desc: 'Track active tokens, running orders and today’s revenue in real time, on any device.' },
  { img: sceneManage, tag: 'Step 3', title: 'Manage Your Menu', desc: 'Add items, set prices and toggle availability instantly across every screen.' },
  { img: sceneReports, tag: 'Step 4', title: 'Sales & Analytics', desc: 'Daily revenue, order history and business insights — all behind a secure owner PIN.' },
  { img: sceneConfirm, tag: 'Step 5', title: 'Instant Kitchen Sync', desc: 'Orders fly to the kitchen and customers get a live token the moment they place an order.' },
];

export default function ProductTourModal({ isOpen, onClose }) {
  const [index, setIndex] = useState(0);
  const [playing, setPlaying] = useState(true);
  const [finished, setFinished] = useState(false);
  const timerRef = useRef(null);

  // Restart the tour each time the modal opens.
  useEffect(() => {
    if (isOpen) {
      setIndex(0);
      setPlaying(true);
      setFinished(false);
    }
  }, [isOpen]);

  // Auto-advance through the scenes while playing.
  useEffect(() => {
    if (!isOpen || !playing || finished) return undefined;
    timerRef.current = setTimeout(() => {
      setIndex((i) => {
        if (i >= SCENES.length - 1) {
          setFinished(true);
          setPlaying(false);
          return i;
        }
        return i + 1;
      });
    }, SCENE_MS);
    return () => clearTimeout(timerRef.current);
  }, [isOpen, playing, finished, index]);

  // Close on Escape.
  useEffect(() => {
    if (!isOpen) return undefined;
    const onKey = (e) => {
      if (e.key === 'Escape') onClose();
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [isOpen, onClose]);

  const replay = () => {
    setIndex(0);
    setFinished(false);
    setPlaying(true);
  };

  const scene = SCENES[index];

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="fixed inset-0 z-50 flex items-center justify-center p-4"
        >
          <div onClick={onClose} className="fixed inset-0 bg-slate-950/85 backdrop-blur-md" />

          <motion.div
            initial={{ scale: 0.95, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            exit={{ scale: 0.95, opacity: 0 }}
            transition={{ duration: 0.25 }}
            className="relative z-10 w-full max-w-4xl bg-slate-900 rounded-3xl shadow-2xl border border-slate-800 overflow-hidden"
          >
            {/* Progress segments + close */}
            <div className="flex items-center gap-2 px-5 pt-5">
              {SCENES.map((_, i) => (
                <div key={i} className="h-1.5 flex-1 rounded-full bg-slate-700 overflow-hidden">
                  {i < index && <div className="h-full w-full bg-primary rounded-full" />}
                  {i === index && (
                    <motion.div
                      key={`seg-${index}-${finished}`}
                      className="h-full bg-primary rounded-full"
                      initial={{ width: finished ? '100%' : '0%' }}
                      animate={{ width: '100%' }}
                      transition={{ duration: finished || !playing ? 0 : SCENE_MS / 1000, ease: 'linear' }}
                    />
                  )}
                </div>
              ))}
              <button
                onClick={onClose}
                aria-label="Close tour"
                className="ml-2 text-slate-400 hover:text-white p-1.5 shrink-0"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="grid md:grid-cols-2 gap-6 md:gap-8 p-6 md:p-8 items-center">
              {/* Phone screenshot */}
              <div className="flex justify-center order-2 md:order-1">
                <div className="relative w-[195px] sm:w-[225px] h-[423px] sm:h-[488px] rounded-[2.4rem] border-[5px] border-black bg-black overflow-hidden shadow-2xl ring-1 ring-slate-700/60">
                  <AnimatePresence mode="wait">
                    <motion.img
                      key={`img-${index}`}
                      src={scene.img}
                      alt={scene.title}
                      initial={{ opacity: 0, x: 24 }}
                      animate={{ opacity: 1, x: 0 }}
                      exit={{ opacity: 0, x: -24 }}
                      transition={{ duration: 0.4 }}
                      className="absolute inset-0 w-full h-full object-contain object-top"
                    />
                  </AnimatePresence>
                  {/* iPhone Dynamic Island */}
                  <div className="absolute top-2 left-1/2 -translate-x-1/2 w-[52px] h-[16px] bg-black rounded-full z-20" />
                  {/* iPhone Home Indicator */}
                  <div className="absolute bottom-1.5 left-1/2 -translate-x-1/2 w-20 h-1 bg-white/70 rounded-full z-20" />
                </div>
              </div>

              {/* Caption + controls */}
              <div className="text-left order-1 md:order-2">
                <AnimatePresence mode="wait">
                  <motion.div
                    key={`txt-${index}`}
                    initial={{ opacity: 0, y: 14 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -14 }}
                    transition={{ duration: 0.4 }}
                  >
                    <span className="inline-block text-xs font-bold uppercase tracking-widest text-primary bg-primary/10 px-3 py-1 rounded-full">
                      {scene.tag}
                    </span>
                    <h3 className="text-2xl sm:text-3xl font-black text-white mt-4 leading-tight">{scene.title}</h3>
                    <p className="text-slate-300 mt-3 leading-relaxed text-sm sm:text-base">{scene.desc}</p>
                  </motion.div>
                </AnimatePresence>

                <div className="flex items-center gap-3 mt-7">
                  {finished ? (
                    <button
                      onClick={replay}
                      className="inline-flex items-center gap-2 bg-primary hover:bg-primary-dark text-white font-bold px-5 py-2.5 rounded-full transition-colors"
                    >
                      <RotateCcw className="w-4 h-4" />
                      <span>Replay</span>
                    </button>
                  ) : (
                    <button
                      onClick={() => setPlaying((p) => !p)}
                      className="inline-flex items-center gap-2 bg-primary hover:bg-primary-dark text-white font-bold px-5 py-2.5 rounded-full transition-colors"
                    >
                      {playing ? <Pause className="w-4 h-4" /> : <Play className="w-4 h-4 fill-white" />}
                      <span>{playing ? 'Pause' : 'Play'}</span>
                    </button>
                  )}
                  <span className="text-xs text-slate-500 font-medium">
                    {index + 1} / {SCENES.length} · 15-second tour
                  </span>
                </div>
              </div>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
