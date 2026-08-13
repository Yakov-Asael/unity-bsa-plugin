(function(){
  function tables(root){ try { return root.querySelectorAll('table'); } catch(e){ return []; } }
  var docs=[document];
  var fr=document.querySelectorAll('iframe');
  for(var i=0;i<fr.length;i++){ try{ if(fr[i].contentDocument) docs.push(fr[i].contentDocument);}catch(e){} }
  for(var d=0;d<docs.length;d++){
    var ts=tables(docs[d]);
    for(var t=0;t<ts.length;t++){
      var rows=ts[t].rows; if(!rows||rows.length<2) continue;
      var hdr=[]; for(var c=0;c<rows[0].cells.length;c++) hdr.push((rows[0].cells[c].innerText||'').trim());
      if(hdr.indexOf('Parent.Name')<0 && hdr.indexOf('Assignee.Name')<0) continue;
      var out=[];
      for(var r=1;r<rows.length;r++){
        var o={};
        for(var c=0;c<rows[r].cells.length && c<hdr.length;c++) o[hdr[c]]=(rows[r].cells[c].innerText||'').trim();
        out.push(o);
      }
      return JSON.stringify({headers:hdr, rows:out});
    }
  }
  return JSON.stringify({error:'no result table found'});
})();
