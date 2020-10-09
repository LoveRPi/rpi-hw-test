<?php

if (isset($_POST['upload'])){

	$file_handle = fopen('data.csv', 'a');
	$array = array_merge([date("Y-m-d H:i:s")],$_POST['upload']);
	fputcsv($file_handle,$array);
	fclose($handle);
	#echo print_r($array,true);
	echo "OK";	
	exit;
}

$data = file_get_contents('data.csv');
$data = explode(PHP_EOL,$data);
array_walk($data,function(&$line){
	$line = explode(',',$line);
},);

echo '<table border="1">';

foreach ($data as $values){
	echo '<tr>';
	foreach ($values as $cell){
		echo '<td>';
		echo htmlspecialchars($cell);
		echo '</td>';
	}
	echo '</tr>';
}

echo '</table>';

?>
