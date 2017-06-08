./terastitcher --import --volin="/data2/20160807_stitching_effect/20160807_stitching_effect_thetaon/Filter488" --projout="/data2/20160807_stitching_effect/20160807_stitching_effect_thetaon/xml_import.xml" --ref1=y --ref2=x --ref3=z --vxl1=0.65 --vxl2=0.65 --vxl3=5 --sparse_data --volin_plugin="TiledXY|2Dseries" --imin_plugin="tiff2D"

./terastitcher --displcompute --projin="/data2/20160807_stitching_effect/20160807_stitching_effect_thetaon/xml_import.xml" --projout="/data2/20160807_stitching_effect/20160807_stitching_effect_thetaon/xml_displcomp.xml" --sV=50 --sH=50 --sD=50 --subvoldim=200

./terastitcher --displproj --projin="/data2/20160807_stitching_effect/20160807_stitching_effect_thetaon/xml_displcomp.xml" --projout="/data2/20160807_stitching_effect/20160807_stitching_effect_thetaon/xml_displproj.xml"

./terastitcher --displthres --projin="/data2/20160807_stitching_effect/20160807_stitching_effect_thetaon/xml_displproj.xml" --projout="/data2/20160807_stitching_effect/20160807_stitching_effect_thetaon/xml_displthres.xml" --threshold=0.5

./terastitcher --placetiles --projin="/data2/20160807_stitching_effect/20160807_stitching_effect_thetaon/xml_displthres.xml" --projout="/data2/20160807_stitching_effect/20160807_stitching_effect_thetaon/xml_merging.xml" --algorithm="MST"

./terastitcher --merge --projin="/data2/20160807_stitching_effect/20160807_stitching_effect_thetaon/xml_merging.xml" --volout="/data2/20160807_stitching_effect/20160807_stitching_effect_thetaon/stitched_thetaoff_for_affine" --resolutions=0 --imout_depth=16 --algorithm="SINBLEND" --R0=3 --R1=13 --C0=3 --C1=13 --volout_plugin="TiledXY|2Dseries" --imout_format="tif"

