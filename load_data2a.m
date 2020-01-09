%Load all data in folder
filename = dir('BCICIV_2a_gdf/*T*.gdf');
cd BCICIV_2a_gdf;
for j = 1:length(filename)
    file = filename(j).name
    [s, HDR] = sload(file);
    type=HDR.EVENT.TYP;
    pos=HDR.EVENT.POS;
    dur=HDR.EVENT.DUR;
 %Extract events
    iv_c1=1; iv_c2=1; iv_c3=1; iv_c4=1;
    for i=1:size(type,1)
        if type(i,1)==769
            subdata=s(pos(i,1):pos(i,1)+dur(i,1),:);
            sig_C1(j,iv_c1,:,:)=subdata;
            iv_c1=iv_c1+1;
        elseif type(i,1)==770
            subdata=s(pos(i,1):pos(i,1)+dur(i,1),:);
            sig_C2(j,iv_c2,:,:)=subdata;
            iv_c2=iv_c2+1;
        elseif type(i,1)==771
            subdata=s(pos(i,1):pos(i,1)+dur(i,1),:);
            sig_C3(j,iv_c3,:,:)=subdata;
            iv_c3=iv_c3+1;
         elseif type(i,1)==772
            subdata=s(pos(i,1):pos(i,1)+dur(i,1),:);
            sig_C4(j,iv_c4,:,:)=subdata;
            iv_c4=iv_c4+1;
        end
    end
end

