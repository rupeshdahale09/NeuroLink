import { FaceLandmarker, FilesetResolver } from 'https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision/vision_bundle.js';

let faceLandmarker;
let videoElement;
let stream;

const closedThreshold = 0.22;
const openThreshold = 0.28;
let eyeClosed = false;
let closedStart = 0;
let pulses = [];
let quietDeadline = 0;

async function setupFaceMesh() {
  const vision = await FilesetResolver.forVisionTasks(
    "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@latest/wasm"
  );
  faceLandmarker = await FaceLandmarker.createFromOptions(vision, {
    baseOptions: {
      modelAssetPath: "https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task",
      delegate: "GPU"
    },
    runningMode: "VIDEO",
    numFaces: 1
  });

  videoElement = document.createElement('video');
  videoElement.setAttribute('autoplay', '');
  videoElement.setAttribute('playsinline', '');
  // Do not append to DOM, keep it headless but processing stream.

  stream = await navigator.mediaDevices.getUserMedia({
    video: { facingMode: "user" },
    audio: false
  });
  videoElement.srcObject = stream;
  
  videoElement.addEventListener('loadeddata', predictWebcam);
}

function dist(p1, p2) {
  const dx = p1.x - p2.x;
  const dy = p1.y - p2.y;
  return Math.sqrt(dx * dx + dy * dy);
}

function handleBlink(ear) {
  const now = Date.now();
  let blinkType = "none";

  const closed = ear < closedThreshold;
  const open = ear > openThreshold;

  if (closed && !eyeClosed) {
    eyeClosed = true;
    closedStart = now;
  } else if (open && eyeClosed) {
    eyeClosed = false;
    const dur = now - closedStart;
    if (dur >= 70 && dur <= 480) {
      if (pulses.length === 0 || now - pulses[pulses.length - 1] >= 120) {
        pulses.push(now);
        quietDeadline = now + 430;
      }
    }
  }

  if (pulses.length > 0 && now > quietDeadline) {
    const count = pulses.length;
    pulses = [];

    if (count >= 3) blinkType = "triple";
    else if (count === 2) blinkType = "double";
    else blinkType = "single";
  }

  return blinkType;
}

let lastVideoTime = -1;
async function predictWebcam() {
  if (videoElement.currentTime !== lastVideoTime) {
    lastVideoTime = videoElement.currentTime;
    const results = faceLandmarker.detectForVideo(videoElement, performance.now());
    
    if (results.faceLandmarks.length > 0) {
      const landmarks = results.faceLandmarks[0];
      
      const rightIris = landmarks[468];
      const leftIris = landmarks[473];
      
      const gazeX = 1.0 - ((rightIris.x + leftIris.x) / 2);
      const gazeY = (rightIris.y + leftIris.y) / 2;

      // Ensure we have eyelid landmarks for Right eye EAR
      const p1 = landmarks[33];
      const p2 = landmarks[160];
      const p3 = landmarks[158];
      const p4 = landmarks[133];
      const p5 = landmarks[153];
      const p6 = landmarks[144];

      const ear = (dist(p2, p6) + dist(p3, p5)) / (2.0 * dist(p1, p4));

      const blink = handleBlink(ear);

      window.dispatchEvent(new CustomEvent('FaceMeshGaze', {
        detail: JSON.stringify({ x: gazeX, y: gazeY, blink: blink })
      }));
    }
  }
  
  if (stream) {
    requestAnimationFrame(predictWebcam);
  }
}

function stopFaceMesh() {
  if (stream) {
    stream.getTracks().forEach(track => track.stop());
    stream = null;
  }
}

window.startFaceMesh = setupFaceMesh;
window.stopFaceMesh = stopFaceMesh;
