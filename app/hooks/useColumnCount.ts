"use client";

import { useState, useEffect } from "react";

export function useColumnCount() {
  const [cols, setCols] = useState(4);

  useEffect(() => {
    function update() {
      const w = window.innerWidth;
      if (w < 480) setCols(2);
      else if (w < 768) setCols(3);
      else if (w < 1024) setCols(4);
      else if (w < 1440) setCols(5);
      else setCols(6);
    }
    update();
    window.addEventListener("resize", update);
    return () => window.removeEventListener("resize", update);
  }, []);

  return cols;
}
