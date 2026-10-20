# Animated avatar sample

Preview only; no app code or Firestore changes in this step.

Built-in image_gen created the closed-eye keyframe from assets/avatars/anime_01.webp with this prompt:

Edit this exact avatar to produce the CLOSED-EYES keyframe for a very subtle blink animation. Change ONLY both eyelids: close both eyes naturally with clean curved anime eyelid lines, cheerful relaxed expression. Keep exact same head position, pose, face proportions, mouth, eyebrows, hair silhouette and strands, clothes, noodle badge, framing, colors, purple circular border, lighting and background. Pixel-aligned image composition is essential: no camera movement, no head tilt, no redraw of other elements. One square image, same full avatar. No text or extra elements.

The generated eyelid regions are composited onto the approved original to keep all other artwork stable. GIF and animated WebP previews run for 4 seconds at 20 fps with a quick blink and a subtle 0.8-degree portrait tilt inside the stationary badge. These previews demonstrate motion; final Flutter playback can use two local keyframes plus a transform rather than bundling 80 frames. Respect reduced motion in the final integration.

Files: noodle-adventurer-preview.gif, noodle-adventurer-preview.webp, closed-keyframe.png, blink-aligned.png.

